// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StudentsTable extends Students with TableInfo<$StudentsTable, Student> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rfidNumberMeta = const VerificationMeta(
    'rfidNumber',
  );
  @override
  late final GeneratedColumn<String> rfidNumber = GeneratedColumn<String>(
    'rfid_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _namaMeta = const VerificationMeta('nama');
  @override
  late final GeneratedColumn<String> nama = GeneratedColumn<String>(
    'nama',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nisnMeta = const VerificationMeta('nisn');
  @override
  late final GeneratedColumn<String> nisn = GeneratedColumn<String>(
    'nisn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kelasMeta = const VerificationMeta('kelas');
  @override
  late final GeneratedColumn<String> kelas = GeneratedColumn<String>(
    'kelas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noTelpWaliMeta = const VerificationMeta(
    'noTelpWali',
  );
  @override
  late final GeneratedColumn<String> noTelpWali = GeneratedColumn<String>(
    'no_telp_wali',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hikRegisteredMeta = const VerificationMeta(
    'hikRegistered',
  );
  @override
  late final GeneratedColumn<bool> hikRegistered = GeneratedColumn<bool>(
    'hik_registered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hik_registered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    rfidNumber,
    nama,
    nisn,
    kelas,
    noTelpWali,
    syncedAt,
    hikRegistered,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(
    Insertable<Student> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('rfid_number')) {
      context.handle(
        _rfidNumberMeta,
        rfidNumber.isAcceptableOrUnknown(data['rfid_number']!, _rfidNumberMeta),
      );
    }
    if (data.containsKey('nama')) {
      context.handle(
        _namaMeta,
        nama.isAcceptableOrUnknown(data['nama']!, _namaMeta),
      );
    } else if (isInserting) {
      context.missing(_namaMeta);
    }
    if (data.containsKey('nisn')) {
      context.handle(
        _nisnMeta,
        nisn.isAcceptableOrUnknown(data['nisn']!, _nisnMeta),
      );
    }
    if (data.containsKey('kelas')) {
      context.handle(
        _kelasMeta,
        kelas.isAcceptableOrUnknown(data['kelas']!, _kelasMeta),
      );
    }
    if (data.containsKey('no_telp_wali')) {
      context.handle(
        _noTelpWaliMeta,
        noTelpWali.isAcceptableOrUnknown(
          data['no_telp_wali']!,
          _noTelpWaliMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('hik_registered')) {
      context.handle(
        _hikRegisteredMeta,
        hikRegistered.isAcceptableOrUnknown(
          data['hik_registered']!,
          _hikRegisteredMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  Student map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Student(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      rfidNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rfid_number'],
      ),
      nama: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama'],
      )!,
      nisn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nisn'],
      ),
      kelas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kelas'],
      ),
      noTelpWali: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_telp_wali'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      ),
      hikRegistered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hik_registered'],
      )!,
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }
}

class Student extends DataClass implements Insertable<Student> {
  final String userId;
  final String? rfidNumber;
  final String nama;
  final String? nisn;
  final String? kelas;
  final String? noTelpWali;
  final int? syncedAt;
  final bool hikRegistered;
  const Student({
    required this.userId,
    this.rfidNumber,
    required this.nama,
    this.nisn,
    this.kelas,
    this.noTelpWali,
    this.syncedAt,
    required this.hikRegistered,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || rfidNumber != null) {
      map['rfid_number'] = Variable<String>(rfidNumber);
    }
    map['nama'] = Variable<String>(nama);
    if (!nullToAbsent || nisn != null) {
      map['nisn'] = Variable<String>(nisn);
    }
    if (!nullToAbsent || kelas != null) {
      map['kelas'] = Variable<String>(kelas);
    }
    if (!nullToAbsent || noTelpWali != null) {
      map['no_telp_wali'] = Variable<String>(noTelpWali);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    map['hik_registered'] = Variable<bool>(hikRegistered);
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      userId: Value(userId),
      rfidNumber: rfidNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(rfidNumber),
      nama: Value(nama),
      nisn: nisn == null && nullToAbsent ? const Value.absent() : Value(nisn),
      kelas: kelas == null && nullToAbsent
          ? const Value.absent()
          : Value(kelas),
      noTelpWali: noTelpWali == null && nullToAbsent
          ? const Value.absent()
          : Value(noTelpWali),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      hikRegistered: Value(hikRegistered),
    );
  }

  factory Student.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Student(
      userId: serializer.fromJson<String>(json['userId']),
      rfidNumber: serializer.fromJson<String?>(json['rfidNumber']),
      nama: serializer.fromJson<String>(json['nama']),
      nisn: serializer.fromJson<String?>(json['nisn']),
      kelas: serializer.fromJson<String?>(json['kelas']),
      noTelpWali: serializer.fromJson<String?>(json['noTelpWali']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
      hikRegistered: serializer.fromJson<bool>(json['hikRegistered']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'rfidNumber': serializer.toJson<String?>(rfidNumber),
      'nama': serializer.toJson<String>(nama),
      'nisn': serializer.toJson<String?>(nisn),
      'kelas': serializer.toJson<String?>(kelas),
      'noTelpWali': serializer.toJson<String?>(noTelpWali),
      'syncedAt': serializer.toJson<int?>(syncedAt),
      'hikRegistered': serializer.toJson<bool>(hikRegistered),
    };
  }

  Student copyWith({
    String? userId,
    Value<String?> rfidNumber = const Value.absent(),
    String? nama,
    Value<String?> nisn = const Value.absent(),
    Value<String?> kelas = const Value.absent(),
    Value<String?> noTelpWali = const Value.absent(),
    Value<int?> syncedAt = const Value.absent(),
    bool? hikRegistered,
  }) => Student(
    userId: userId ?? this.userId,
    rfidNumber: rfidNumber.present ? rfidNumber.value : this.rfidNumber,
    nama: nama ?? this.nama,
    nisn: nisn.present ? nisn.value : this.nisn,
    kelas: kelas.present ? kelas.value : this.kelas,
    noTelpWali: noTelpWali.present ? noTelpWali.value : this.noTelpWali,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    hikRegistered: hikRegistered ?? this.hikRegistered,
  );
  Student copyWithCompanion(StudentsCompanion data) {
    return Student(
      userId: data.userId.present ? data.userId.value : this.userId,
      rfidNumber: data.rfidNumber.present
          ? data.rfidNumber.value
          : this.rfidNumber,
      nama: data.nama.present ? data.nama.value : this.nama,
      nisn: data.nisn.present ? data.nisn.value : this.nisn,
      kelas: data.kelas.present ? data.kelas.value : this.kelas,
      noTelpWali: data.noTelpWali.present
          ? data.noTelpWali.value
          : this.noTelpWali,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      hikRegistered: data.hikRegistered.present
          ? data.hikRegistered.value
          : this.hikRegistered,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Student(')
          ..write('userId: $userId, ')
          ..write('rfidNumber: $rfidNumber, ')
          ..write('nama: $nama, ')
          ..write('nisn: $nisn, ')
          ..write('kelas: $kelas, ')
          ..write('noTelpWali: $noTelpWali, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('hikRegistered: $hikRegistered')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    rfidNumber,
    nama,
    nisn,
    kelas,
    noTelpWali,
    syncedAt,
    hikRegistered,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Student &&
          other.userId == this.userId &&
          other.rfidNumber == this.rfidNumber &&
          other.nama == this.nama &&
          other.nisn == this.nisn &&
          other.kelas == this.kelas &&
          other.noTelpWali == this.noTelpWali &&
          other.syncedAt == this.syncedAt &&
          other.hikRegistered == this.hikRegistered);
}

class StudentsCompanion extends UpdateCompanion<Student> {
  final Value<String> userId;
  final Value<String?> rfidNumber;
  final Value<String> nama;
  final Value<String?> nisn;
  final Value<String?> kelas;
  final Value<String?> noTelpWali;
  final Value<int?> syncedAt;
  final Value<bool> hikRegistered;
  final Value<int> rowid;
  const StudentsCompanion({
    this.userId = const Value.absent(),
    this.rfidNumber = const Value.absent(),
    this.nama = const Value.absent(),
    this.nisn = const Value.absent(),
    this.kelas = const Value.absent(),
    this.noTelpWali = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.hikRegistered = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    required String userId,
    this.rfidNumber = const Value.absent(),
    required String nama,
    this.nisn = const Value.absent(),
    this.kelas = const Value.absent(),
    this.noTelpWali = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.hikRegistered = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       nama = Value(nama);
  static Insertable<Student> custom({
    Expression<String>? userId,
    Expression<String>? rfidNumber,
    Expression<String>? nama,
    Expression<String>? nisn,
    Expression<String>? kelas,
    Expression<String>? noTelpWali,
    Expression<int>? syncedAt,
    Expression<bool>? hikRegistered,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (rfidNumber != null) 'rfid_number': rfidNumber,
      if (nama != null) 'nama': nama,
      if (nisn != null) 'nisn': nisn,
      if (kelas != null) 'kelas': kelas,
      if (noTelpWali != null) 'no_telp_wali': noTelpWali,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (hikRegistered != null) 'hik_registered': hikRegistered,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? userId,
    Value<String?>? rfidNumber,
    Value<String>? nama,
    Value<String?>? nisn,
    Value<String?>? kelas,
    Value<String?>? noTelpWali,
    Value<int?>? syncedAt,
    Value<bool>? hikRegistered,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      userId: userId ?? this.userId,
      rfidNumber: rfidNumber ?? this.rfidNumber,
      nama: nama ?? this.nama,
      nisn: nisn ?? this.nisn,
      kelas: kelas ?? this.kelas,
      noTelpWali: noTelpWali ?? this.noTelpWali,
      syncedAt: syncedAt ?? this.syncedAt,
      hikRegistered: hikRegistered ?? this.hikRegistered,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (rfidNumber.present) {
      map['rfid_number'] = Variable<String>(rfidNumber.value);
    }
    if (nama.present) {
      map['nama'] = Variable<String>(nama.value);
    }
    if (nisn.present) {
      map['nisn'] = Variable<String>(nisn.value);
    }
    if (kelas.present) {
      map['kelas'] = Variable<String>(kelas.value);
    }
    if (noTelpWali.present) {
      map['no_telp_wali'] = Variable<String>(noTelpWali.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (hikRegistered.present) {
      map['hik_registered'] = Variable<bool>(hikRegistered.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('userId: $userId, ')
          ..write('rfidNumber: $rfidNumber, ')
          ..write('nama: $nama, ')
          ..write('nisn: $nisn, ')
          ..write('kelas: $kelas, ')
          ..write('noTelpWali: $noTelpWali, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('hikRegistered: $hikRegistered, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TapRecordsTable extends TapRecords
    with TableInfo<$TapRecordsTable, TapRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TapRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rfidNumberMeta = const VerificationMeta(
    'rfidNumber',
  );
  @override
  late final GeneratedColumn<String> rfidNumber = GeneratedColumn<String>(
    'rfid_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceTimeMeta = const VerificationMeta(
    'deviceTime',
  );
  @override
  late final GeneratedColumn<int> deviceTime = GeneratedColumn<int>(
    'device_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hikSerialNoMeta = const VerificationMeta(
    'hikSerialNo',
  );
  @override
  late final GeneratedColumn<int> hikSerialNo = GeneratedColumn<int>(
    'hik_serial_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<int> publishedAt = GeneratedColumn<int>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rfidNumber,
    eventType,
    deviceTime,
    reason,
    hikSerialNo,
    createdAt,
    publishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tap_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<TapRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rfid_number')) {
      context.handle(
        _rfidNumberMeta,
        rfidNumber.isAcceptableOrUnknown(data['rfid_number']!, _rfidNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_rfidNumberMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('device_time')) {
      context.handle(
        _deviceTimeMeta,
        deviceTime.isAcceptableOrUnknown(data['device_time']!, _deviceTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceTimeMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('hik_serial_no')) {
      context.handle(
        _hikSerialNoMeta,
        hikSerialNo.isAcceptableOrUnknown(
          data['hik_serial_no']!,
          _hikSerialNoMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {rfidNumber, deviceTime},
  ];
  @override
  TapRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TapRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rfidNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rfid_number'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      deviceTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_time'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      hikSerialNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hik_serial_no'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}published_at'],
      ),
    );
  }

  @override
  $TapRecordsTable createAlias(String alias) {
    return $TapRecordsTable(attachedDatabase, alias);
  }
}

class TapRecord extends DataClass implements Insertable<TapRecord> {
  final String id;
  final String rfidNumber;
  final String eventType;
  final int deviceTime;
  final String? reason;
  final int? hikSerialNo;
  final int createdAt;
  final int? publishedAt;
  const TapRecord({
    required this.id,
    required this.rfidNumber,
    required this.eventType,
    required this.deviceTime,
    this.reason,
    this.hikSerialNo,
    required this.createdAt,
    this.publishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rfid_number'] = Variable<String>(rfidNumber);
    map['event_type'] = Variable<String>(eventType);
    map['device_time'] = Variable<int>(deviceTime);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || hikSerialNo != null) {
      map['hik_serial_no'] = Variable<int>(hikSerialNo);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<int>(publishedAt);
    }
    return map;
  }

  TapRecordsCompanion toCompanion(bool nullToAbsent) {
    return TapRecordsCompanion(
      id: Value(id),
      rfidNumber: Value(rfidNumber),
      eventType: Value(eventType),
      deviceTime: Value(deviceTime),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      hikSerialNo: hikSerialNo == null && nullToAbsent
          ? const Value.absent()
          : Value(hikSerialNo),
      createdAt: Value(createdAt),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
    );
  }

  factory TapRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TapRecord(
      id: serializer.fromJson<String>(json['id']),
      rfidNumber: serializer.fromJson<String>(json['rfidNumber']),
      eventType: serializer.fromJson<String>(json['eventType']),
      deviceTime: serializer.fromJson<int>(json['deviceTime']),
      reason: serializer.fromJson<String?>(json['reason']),
      hikSerialNo: serializer.fromJson<int?>(json['hikSerialNo']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      publishedAt: serializer.fromJson<int?>(json['publishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rfidNumber': serializer.toJson<String>(rfidNumber),
      'eventType': serializer.toJson<String>(eventType),
      'deviceTime': serializer.toJson<int>(deviceTime),
      'reason': serializer.toJson<String?>(reason),
      'hikSerialNo': serializer.toJson<int?>(hikSerialNo),
      'createdAt': serializer.toJson<int>(createdAt),
      'publishedAt': serializer.toJson<int?>(publishedAt),
    };
  }

  TapRecord copyWith({
    String? id,
    String? rfidNumber,
    String? eventType,
    int? deviceTime,
    Value<String?> reason = const Value.absent(),
    Value<int?> hikSerialNo = const Value.absent(),
    int? createdAt,
    Value<int?> publishedAt = const Value.absent(),
  }) => TapRecord(
    id: id ?? this.id,
    rfidNumber: rfidNumber ?? this.rfidNumber,
    eventType: eventType ?? this.eventType,
    deviceTime: deviceTime ?? this.deviceTime,
    reason: reason.present ? reason.value : this.reason,
    hikSerialNo: hikSerialNo.present ? hikSerialNo.value : this.hikSerialNo,
    createdAt: createdAt ?? this.createdAt,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
  );
  TapRecord copyWithCompanion(TapRecordsCompanion data) {
    return TapRecord(
      id: data.id.present ? data.id.value : this.id,
      rfidNumber: data.rfidNumber.present
          ? data.rfidNumber.value
          : this.rfidNumber,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      deviceTime: data.deviceTime.present
          ? data.deviceTime.value
          : this.deviceTime,
      reason: data.reason.present ? data.reason.value : this.reason,
      hikSerialNo: data.hikSerialNo.present
          ? data.hikSerialNo.value
          : this.hikSerialNo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TapRecord(')
          ..write('id: $id, ')
          ..write('rfidNumber: $rfidNumber, ')
          ..write('eventType: $eventType, ')
          ..write('deviceTime: $deviceTime, ')
          ..write('reason: $reason, ')
          ..write('hikSerialNo: $hikSerialNo, ')
          ..write('createdAt: $createdAt, ')
          ..write('publishedAt: $publishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rfidNumber,
    eventType,
    deviceTime,
    reason,
    hikSerialNo,
    createdAt,
    publishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TapRecord &&
          other.id == this.id &&
          other.rfidNumber == this.rfidNumber &&
          other.eventType == this.eventType &&
          other.deviceTime == this.deviceTime &&
          other.reason == this.reason &&
          other.hikSerialNo == this.hikSerialNo &&
          other.createdAt == this.createdAt &&
          other.publishedAt == this.publishedAt);
}

class TapRecordsCompanion extends UpdateCompanion<TapRecord> {
  final Value<String> id;
  final Value<String> rfidNumber;
  final Value<String> eventType;
  final Value<int> deviceTime;
  final Value<String?> reason;
  final Value<int?> hikSerialNo;
  final Value<int> createdAt;
  final Value<int?> publishedAt;
  final Value<int> rowid;
  const TapRecordsCompanion({
    this.id = const Value.absent(),
    this.rfidNumber = const Value.absent(),
    this.eventType = const Value.absent(),
    this.deviceTime = const Value.absent(),
    this.reason = const Value.absent(),
    this.hikSerialNo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TapRecordsCompanion.insert({
    required String id,
    required String rfidNumber,
    required String eventType,
    required int deviceTime,
    this.reason = const Value.absent(),
    this.hikSerialNo = const Value.absent(),
    required int createdAt,
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rfidNumber = Value(rfidNumber),
       eventType = Value(eventType),
       deviceTime = Value(deviceTime),
       createdAt = Value(createdAt);
  static Insertable<TapRecord> custom({
    Expression<String>? id,
    Expression<String>? rfidNumber,
    Expression<String>? eventType,
    Expression<int>? deviceTime,
    Expression<String>? reason,
    Expression<int>? hikSerialNo,
    Expression<int>? createdAt,
    Expression<int>? publishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rfidNumber != null) 'rfid_number': rfidNumber,
      if (eventType != null) 'event_type': eventType,
      if (deviceTime != null) 'device_time': deviceTime,
      if (reason != null) 'reason': reason,
      if (hikSerialNo != null) 'hik_serial_no': hikSerialNo,
      if (createdAt != null) 'created_at': createdAt,
      if (publishedAt != null) 'published_at': publishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TapRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? rfidNumber,
    Value<String>? eventType,
    Value<int>? deviceTime,
    Value<String?>? reason,
    Value<int?>? hikSerialNo,
    Value<int>? createdAt,
    Value<int?>? publishedAt,
    Value<int>? rowid,
  }) {
    return TapRecordsCompanion(
      id: id ?? this.id,
      rfidNumber: rfidNumber ?? this.rfidNumber,
      eventType: eventType ?? this.eventType,
      deviceTime: deviceTime ?? this.deviceTime,
      reason: reason ?? this.reason,
      hikSerialNo: hikSerialNo ?? this.hikSerialNo,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rfidNumber.present) {
      map['rfid_number'] = Variable<String>(rfidNumber.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (deviceTime.present) {
      map['device_time'] = Variable<int>(deviceTime.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (hikSerialNo.present) {
      map['hik_serial_no'] = Variable<int>(hikSerialNo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<int>(publishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TapRecordsCompanion(')
          ..write('id: $id, ')
          ..write('rfidNumber: $rfidNumber, ')
          ..write('eventType: $eventType, ')
          ..write('deviceTime: $deviceTime, ')
          ..write('reason: $reason, ')
          ..write('hikSerialNo: $hikSerialNo, ')
          ..write('createdAt: $createdAt, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $TapRecordsTable tapRecords = $TapRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [students, tapRecords];
}

typedef $$StudentsTableCreateCompanionBuilder =
    StudentsCompanion Function({
      required String userId,
      Value<String?> rfidNumber,
      required String nama,
      Value<String?> nisn,
      Value<String?> kelas,
      Value<String?> noTelpWali,
      Value<int?> syncedAt,
      Value<bool> hikRegistered,
      Value<int> rowid,
    });
typedef $$StudentsTableUpdateCompanionBuilder =
    StudentsCompanion Function({
      Value<String> userId,
      Value<String?> rfidNumber,
      Value<String> nama,
      Value<String?> nisn,
      Value<String?> kelas,
      Value<String?> noTelpWali,
      Value<int?> syncedAt,
      Value<bool> hikRegistered,
      Value<int> rowid,
    });

class $$StudentsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rfidNumber => $composableBuilder(
    column: $table.rfidNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nisn => $composableBuilder(
    column: $table.nisn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kelas => $composableBuilder(
    column: $table.kelas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noTelpWali => $composableBuilder(
    column: $table.noTelpWali,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hikRegistered => $composableBuilder(
    column: $table.hikRegistered,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rfidNumber => $composableBuilder(
    column: $table.rfidNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nisn => $composableBuilder(
    column: $table.nisn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kelas => $composableBuilder(
    column: $table.kelas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noTelpWali => $composableBuilder(
    column: $table.noTelpWali,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hikRegistered => $composableBuilder(
    column: $table.hikRegistered,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get rfidNumber => $composableBuilder(
    column: $table.rfidNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nama =>
      $composableBuilder(column: $table.nama, builder: (column) => column);

  GeneratedColumn<String> get nisn =>
      $composableBuilder(column: $table.nisn, builder: (column) => column);

  GeneratedColumn<String> get kelas =>
      $composableBuilder(column: $table.kelas, builder: (column) => column);

  GeneratedColumn<String> get noTelpWali => $composableBuilder(
    column: $table.noTelpWali,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<bool> get hikRegistered => $composableBuilder(
    column: $table.hikRegistered,
    builder: (column) => column,
  );
}

class $$StudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTable,
          Student,
          $$StudentsTableFilterComposer,
          $$StudentsTableOrderingComposer,
          $$StudentsTableAnnotationComposer,
          $$StudentsTableCreateCompanionBuilder,
          $$StudentsTableUpdateCompanionBuilder,
          (Student, BaseReferences<_$AppDatabase, $StudentsTable, Student>),
          Student,
          PrefetchHooks Function()
        > {
  $$StudentsTableTableManager(_$AppDatabase db, $StudentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> rfidNumber = const Value.absent(),
                Value<String> nama = const Value.absent(),
                Value<String?> nisn = const Value.absent(),
                Value<String?> kelas = const Value.absent(),
                Value<String?> noTelpWali = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<bool> hikRegistered = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion(
                userId: userId,
                rfidNumber: rfidNumber,
                nama: nama,
                nisn: nisn,
                kelas: kelas,
                noTelpWali: noTelpWali,
                syncedAt: syncedAt,
                hikRegistered: hikRegistered,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> rfidNumber = const Value.absent(),
                required String nama,
                Value<String?> nisn = const Value.absent(),
                Value<String?> kelas = const Value.absent(),
                Value<String?> noTelpWali = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<bool> hikRegistered = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion.insert(
                userId: userId,
                rfidNumber: rfidNumber,
                nama: nama,
                nisn: nisn,
                kelas: kelas,
                noTelpWali: noTelpWali,
                syncedAt: syncedAt,
                hikRegistered: hikRegistered,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTable,
      Student,
      $$StudentsTableFilterComposer,
      $$StudentsTableOrderingComposer,
      $$StudentsTableAnnotationComposer,
      $$StudentsTableCreateCompanionBuilder,
      $$StudentsTableUpdateCompanionBuilder,
      (Student, BaseReferences<_$AppDatabase, $StudentsTable, Student>),
      Student,
      PrefetchHooks Function()
    >;
typedef $$TapRecordsTableCreateCompanionBuilder =
    TapRecordsCompanion Function({
      required String id,
      required String rfidNumber,
      required String eventType,
      required int deviceTime,
      Value<String?> reason,
      Value<int?> hikSerialNo,
      required int createdAt,
      Value<int?> publishedAt,
      Value<int> rowid,
    });
typedef $$TapRecordsTableUpdateCompanionBuilder =
    TapRecordsCompanion Function({
      Value<String> id,
      Value<String> rfidNumber,
      Value<String> eventType,
      Value<int> deviceTime,
      Value<String?> reason,
      Value<int?> hikSerialNo,
      Value<int> createdAt,
      Value<int?> publishedAt,
      Value<int> rowid,
    });

class $$TapRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $TapRecordsTable> {
  $$TapRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rfidNumber => $composableBuilder(
    column: $table.rfidNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hikSerialNo => $composableBuilder(
    column: $table.hikSerialNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TapRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $TapRecordsTable> {
  $$TapRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rfidNumber => $composableBuilder(
    column: $table.rfidNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hikSerialNo => $composableBuilder(
    column: $table.hikSerialNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TapRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TapRecordsTable> {
  $$TapRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rfidNumber => $composableBuilder(
    column: $table.rfidNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get hikSerialNo => $composableBuilder(
    column: $table.hikSerialNo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );
}

class $$TapRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TapRecordsTable,
          TapRecord,
          $$TapRecordsTableFilterComposer,
          $$TapRecordsTableOrderingComposer,
          $$TapRecordsTableAnnotationComposer,
          $$TapRecordsTableCreateCompanionBuilder,
          $$TapRecordsTableUpdateCompanionBuilder,
          (
            TapRecord,
            BaseReferences<_$AppDatabase, $TapRecordsTable, TapRecord>,
          ),
          TapRecord,
          PrefetchHooks Function()
        > {
  $$TapRecordsTableTableManager(_$AppDatabase db, $TapRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TapRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TapRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TapRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rfidNumber = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> deviceTime = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int?> hikSerialNo = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TapRecordsCompanion(
                id: id,
                rfidNumber: rfidNumber,
                eventType: eventType,
                deviceTime: deviceTime,
                reason: reason,
                hikSerialNo: hikSerialNo,
                createdAt: createdAt,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rfidNumber,
                required String eventType,
                required int deviceTime,
                Value<String?> reason = const Value.absent(),
                Value<int?> hikSerialNo = const Value.absent(),
                required int createdAt,
                Value<int?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TapRecordsCompanion.insert(
                id: id,
                rfidNumber: rfidNumber,
                eventType: eventType,
                deviceTime: deviceTime,
                reason: reason,
                hikSerialNo: hikSerialNo,
                createdAt: createdAt,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TapRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TapRecordsTable,
      TapRecord,
      $$TapRecordsTableFilterComposer,
      $$TapRecordsTableOrderingComposer,
      $$TapRecordsTableAnnotationComposer,
      $$TapRecordsTableCreateCompanionBuilder,
      $$TapRecordsTableUpdateCompanionBuilder,
      (TapRecord, BaseReferences<_$AppDatabase, $TapRecordsTable, TapRecord>),
      TapRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$TapRecordsTableTableManager get tapRecords =>
      $$TapRecordsTableTableManager(_db, _db.tapRecords);
}
