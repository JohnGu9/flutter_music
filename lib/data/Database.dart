import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

testDb() async {
  final LinkedList linkedList = await LinkedList.easeLinkedList<String>(
      database: 'test', table: 'test', drop: true);
//  linkedList.add('john0');
//  linkedList.add('john1');
//  linkedList.add('john2');

  linkedList.addAll(['john0', 'john1', 'john2']);

  linkedList.insert(0, 'john3');
  linkedList.insert(0, 'john4');
  linkedList.insert(0, 'john5');

  print(linkedList.list);
  print(await linkedList.getMap);
  return;
}

class DatabaseKey<T> {
  const DatabaseKey({@required this.keyName});

  final keyName;

  static final typeMap = {
    const DatabaseKey<String>().runtimeType: 'TEXT',
    const DatabaseKey<int>().runtimeType: 'INTEGER',
    const DatabaseKey<bool>().runtimeType: 'BIT',
    const DatabaseKey<double>().runtimeType: 'REAL',
    const DatabaseKey().runtimeType: 'BLOB',
  };

  @override
  String toString() {
    return ', ' + keyName + ' ' + typeMap[this.runtimeType];
  }

  String toPrimaryString() {
    return keyName +
        ' ' +
        typeMap[this.runtimeType] +
        ' PRIMARY KEY NOT NULL UNIQUE';
  }

  String toWhereString() {
    return keyName + ' = ?';
  }
}

class LinkedList<T> {
  LinkedList({this.database}) : assert(database != null);

  final Database database;
  String table;
  List<T> list;

  final DatabaseKey primaryKey = DatabaseKey<T>(keyName: 'filePath');
  final DatabaseKey previousKey = DatabaseKey<T>(keyName: 'previous');
  final DatabaseKey nextKey = DatabaseKey<T>(keyName: 'next');

  static const previousIndex = 0;
  static const nextIndex = 1;

  static String generateStructure(List<DatabaseKey> keys) {
    String res = "(";
    res += keys[0].toPrimaryString();
    res += keys[1].toString();
    res += keys[2].toString();
    return res + ")";
  }

  static Future<Database> easeDatabase(String name) async =>
      openDatabase(join(await getDatabasesPath(), '$name.db'));

  static Future<LinkedList<T>> easeLinkedList<T>({
    @required String database,
    @required String table,
    bool drop = false,
  }) async =>
      await LinkedList<T>(database: await easeDatabase(database))
          .bindTable(table, drop);

  Future<LinkedList<T>> bindTable(String tableName, bool drop) async {
    this.table = tableName;

    /// [drop] whether drop the existing table
    if (drop) {
      await database.execute("drop table if exists $tableName");
    }
    await database.execute("CREATE TABLE IF NOT EXISTS $tableName" +
        generateStructure([primaryKey, previousKey, nextKey]));
    await _initialize();
    return this;
  }

  _initialize() async {
    List<Map<String, dynamic>> maps = await this.maps;
    Map primaryKeyMap = Map<dynamic, List<dynamic>>();
    list = List();
    T first;
    T last;
    if (maps == null || maps.length == 0) {
      return;
    }
    for (final map in maps) {
      primaryKeyMap[map[primaryKey.keyName]] = [
        map[previousKey.keyName],
        map[nextKey.keyName]
      ];
      if (map[previousKey.keyName] == null) {
        first = map[primaryKey.keyName];
      }
      if (map[nextKey.keyName] == null) {
        last = map[primaryKey.keyName];
      }
    }
    assert(first != null && last != null);
    T current = first;
    while (current != null) {
      list.add(current);
      current = primaryKeyMap[current][nextIndex];
    }
  }

  Future<List> get maps async => await database.query('$table');

  get getMap async {
    List<Map<String, dynamic>> maps = await this.maps;
    Map primaryKeyMap = Map<dynamic, List<dynamic>>();
    if (maps == null || maps.length == 0) {
      return primaryKeyMap;
    }
    for (final map in maps) {
      primaryKeyMap[map[primaryKey.keyName]] = [
        map[previousKey.keyName],
        map[nextKey.keyName]
      ];
    }
    return primaryKeyMap;
  }

  Map<String, T> elementToMap(int index) {
    final map = Map<String, T>();
    map[primaryKey.keyName] = list[index];
    map[previousKey.keyName] = index == 0 ? null : list[index - 1];
    map[nextKey.keyName] = index == list.length - 1 ? null : list[index + 1];
    return map;
  }

  T operator [](int index) => list[index];

  operator []=(int index, T value) async {
    list[index] = value;
    await database.update(
      table,
      elementToMap(index),
      where: primaryKey.toWhereString(),
      whereArgs: [list[index]],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  add(T value) {
    if (list.contains(value)) {
      /// linked list can't contains two same value
      return;
    }
    list.add(value);
    print(elementToMap(list.length - 1));
    if (list.length == 1) {
      database.insert(
        table,
        elementToMap(list.length - 1),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      database.update(
        table,
        elementToMap(list.length - 2),
        where: primaryKey.toWhereString(),
        whereArgs: [list[list.length - 2]],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      database.insert(
        table,
        elementToMap(list.length - 1),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  addAll(Iterable iterable) {
    assert(iterable.length != 0);
    final lastPosition = list.length;
    for (final element in iterable) {
      if (!list.contains(element)) {
        list.add(element);
      }
    }
    if (lastPosition != 0) {
      database.update(
        table,
        elementToMap(lastPosition - 1),
        where: primaryKey.toWhereString(),
        whereArgs: [list[lastPosition - 1]],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (int index = lastPosition; index < list.length; index++) {
      database.insert(
        table,
        elementToMap(index),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  insert(int index, T element) {
    list.insert(index, element);
    if (index != 0) {
      database.update(
        table,
        elementToMap(index - 1),
        where: primaryKey.toWhereString(),
        whereArgs: [list[index - 1]],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    if (index != list.length - 1) {
      database.update(
        table,
        elementToMap(index + 1),
        where: primaryKey.toWhereString(),
        whereArgs: [list[index + 1]],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    database.insert(
      table,
      elementToMap(index),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  T removeAt(int index) {
    database.delete(
      table,
      where: primaryKey.toWhereString(),
      whereArgs: [list[index]],
    );
    final res = list.removeAt(index);
    database.update(
      table,
      elementToMap(index - 1),
      where: primaryKey.toWhereString(),
      whereArgs: [list[index - 1]],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    database.update(
      table,
      elementToMap(index),
      where: primaryKey.toWhereString(),
      whereArgs: [list[index]],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return res;
  }

  reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    } else if (oldIndex < newIndex) {
      insert(newIndex, list[oldIndex]);
      removeAt(oldIndex);
    } else {
      final value = removeAt(oldIndex);
      insert(newIndex, value);
    }
  }
}

class SQLiteLinkedList<T> {
  SQLiteLinkedList(this.database);

  final Database database;
  String tableName;
  Map<T, List<T>> primaryKeyMap;
  List<T> list;
  T first;
  T last;

  final DatabaseKey primaryKey = DatabaseKey<T>(keyName: 'filePath');
  final DatabaseKey previousKey = DatabaseKey<T>(keyName: 'previous');
  final DatabaseKey nextKey = DatabaseKey<T>(keyName: 'next');

  static String generateStructure(List<DatabaseKey> keys) {
    String res = "(";
    res += keys[0].toPrimaryString();
    res += keys[1].toString();
    res += keys[2].toString();
    return res + ")";
  }

  static const previousIndex = 0;
  static const nextIndex = 1;

  static Future<Database> easeDatabase(String name) async =>
      openDatabase(join(await getDatabasesPath(), '$name.db'));

  static Future<SQLiteLinkedList<T>> easeLinkedList<T>({
    @required String database,
    @required String table,
    bool drop = false,
  }) async {
    final res = SQLiteLinkedList<T>(await easeDatabase(database));
    await res.bindTable(table, drop: drop);
    return res;
  }

  Map<String, T> itemToMap(T key, List<T> value) {
    final map = Map<String, T>();
    map[primaryKey.keyName] = key;
    map[previousKey.keyName] = value[previousIndex];
    map[nextKey.keyName] = value[nextIndex];
    return map;
  }

  bindTable(String tableName, {bool drop = false}) async {
    this.tableName = tableName;

    /// [drop] whether drop the table exists
    if (drop) {
      await database.execute("drop table if exists $tableName");
    }
    await database.execute("CREATE TABLE IF NOT EXISTS $tableName" +
        generateStructure([primaryKey, previousKey, nextKey]));
    _initializeMap(await database.query('$tableName'));
    _initializeList();
  }

  /// initialize [primaryKeyMap] from [maps]
  /// call after query [maps] from database
  void _initializeMap(List<Map<String, dynamic>> maps) {
    primaryKeyMap = Map<T, List<T>>();
    if (maps == null || maps.length == 0) {
      return;
    }
    for (final map in maps) {
      primaryKeyMap[map[primaryKey.keyName]] = [
        map[previousKey.keyName],
        map[nextKey.keyName]
      ];
      if (map[previousKey.keyName] == null) {
        first = map[primaryKey.keyName];
      }
      if (map[nextKey.keyName] == null) {
        last = map[primaryKey.keyName];
      }
    }
    assert(first != null && last != null);
    return;
  }

  /// initialize [list] from [primaryKeyMap]
  /// call after [_initializeMap] return
  void _initializeList() {
    assert(primaryKeyMap != null);
    list = List();
    T index = first;
    while (index != null) {
      list.add(index);
      index = primaryKeyMap[index][nextIndex];
    }
  }

  add(T value) async {
    if (primaryKeyMap.containsKey(value)) {
      /// linked list don't contains two same values
      /// any value must be unique
      return;
    } else if (list.length == 0) {
      list.add(value);
      primaryKeyMap[value] = <T>[null, null];
      last = first = value;
      await database.insert(
        tableName,
        itemToMap(last, primaryKeyMap[last]),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }
    list.add(value);
    primaryKeyMap[last][nextIndex] = value;
    primaryKeyMap[value] = [last, null];
    final secondLast = last;
    last = value;
    await Future.wait([
      database.insert(
        tableName,
        itemToMap(secondLast, primaryKeyMap[secondLast]),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
      database.insert(
        tableName,
        itemToMap(last, primaryKeyMap[last]),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    ]);
  }

  addAll(Iterable iterable) async {
    for (final item in iterable) {
      await add(item);
    }
  }

  sync(Iterable iterable) async {
    List copy = List.from(iterable);
    for (int i = 0; i < list.length;) {
      copy.contains(list[i]) ? copy.removeAt(i++) : await removeAt(i);
    }
    await addAll(copy);
  }

  insert(int index, T value) async {
    if (primaryKeyMap.containsKey(value)) {
      /// linked list don't contains two same values
      /// any value must be unique
      return;
    }

    Future future;

    if (index == 0) {
      primaryKeyMap[first][previousIndex] = value;
      primaryKeyMap[value] = [null, first];
      final secondFirst = first;
      first = value;
      future = Future.wait([
        database.insert(
          tableName,
          itemToMap(secondFirst, primaryKeyMap[secondFirst]),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
        database.insert(
          tableName,
          itemToMap(first, primaryKeyMap[first]),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ]);
    } else if (index == list.length) {
      primaryKeyMap[last][nextIndex] = value;
      primaryKeyMap[value] = [last, null];
      final secondLast = last;
      last = value;
      future = Future.wait([
        database.insert(
          tableName,
          itemToMap(secondLast, primaryKeyMap[secondLast]),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
        database.insert(
          tableName,
          itemToMap(last, primaryKeyMap[last]),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ]);
    } else {
      primaryKeyMap[list[index - 1]][nextIndex] = value;
      primaryKeyMap[list[index]][previousIndex] = value;
      primaryKeyMap[value] = [list[index - 1], list[index]];
      future = Future.wait([
        database.insert(
          tableName,
          itemToMap(value, primaryKeyMap[value]),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
        database.update(
          tableName,
          itemToMap(list[index - 1], primaryKeyMap[list[index - 1]]),
          where: primaryKey.toWhereString(),
          whereArgs: [list[index - 1]],
        ),
        database.update(
          tableName,
          itemToMap(list[index], primaryKeyMap[list[index]]),
          where: primaryKey.toWhereString(),
          whereArgs: [list[index]],
        ),
      ]);
    }
    list.insert(index, value);
    await future;
  }

  dynamic removeAt(int index) async {
    Future future;
    T res;
    if (list.length == 1) {
      primaryKeyMap.remove(first);
      res = list.removeAt(index);
      future = database.delete(tableName,
          where: primaryKey.toWhereString(), whereArgs: [first]);
      first = last = null;
    } else if (index == 0) {
      primaryKeyMap[list[index + 1]][previousIndex] = null;
      future = Future.wait([
        database.delete(
          tableName,
          where: primaryKey.toWhereString(),
          whereArgs: [first],
        ),
        database.update(
          tableName,
          itemToMap(list[index + 1], primaryKeyMap[list[index + 1]]),
          where: primaryKey.toWhereString(),
          whereArgs: [list[index + 1]],
        )
      ]);
      primaryKeyMap.remove(first);
      res = list.removeAt(index);
      first = list[index + 1];
    } else if (index == list.length - 1) {
      primaryKeyMap[list[index - 1]][nextIndex] = null;
      future = Future.wait([
        database.delete(
          tableName,
          where: primaryKey.toWhereString(),
          whereArgs: [last],
        ),
        database.update(
          tableName,
          itemToMap(list[index - 1], primaryKeyMap[list[index - 1]]),
          where: primaryKey.toWhereString(),
          whereArgs: [list[index - 1]],
        )
      ]);
      primaryKeyMap.remove(last);
      res = list.removeAt(index);
      last = list[index - 1];
    } else {
      primaryKeyMap[list[index - 1]][nextIndex] = list[index + 1];
      primaryKeyMap[list[index + 1]][previousIndex] = list[index - 1];
      future = Future.wait([
        database.delete(
          tableName,
          where: primaryKey.toWhereString(),
          whereArgs: [list[index]],
        ),
        database.update(
          tableName,
          itemToMap(list[index - 1], primaryKeyMap[list[index - 1]]),
          where: primaryKey.toWhereString(),
          whereArgs: [list[index - 1]],
        ),
        database.update(
          tableName,
          itemToMap(list[index + 1], primaryKeyMap[list[index + 1]]),
          where: primaryKey.toWhereString(),
          whereArgs: [list[index + 1]],
        ),
      ]);
      primaryKeyMap.remove(list[index]);
      res = list.removeAt(index);
    }
    await future;
    return res;
  }

  reorder(int oldIndex, int newIndex) async {
    assert(oldIndex < list.length && newIndex < list.length);
    if (oldIndex == newIndex) {
      return;
    }
    if (oldIndex < newIndex) {
      T value = await removeAt(oldIndex);
      await insert(newIndex - 1, value);
    } else {
      T value = await removeAt(oldIndex);
      await insert(newIndex, value);
    }
  }
}
