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
  static const VerificationMeta _cardSyncStatusMeta = const VerificationMeta(
    'cardSyncStatus',
  );
  @override
  late final GeneratedColumn<String> cardSyncStatus = GeneratedColumn<String>(
    'card_sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
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
    cardSyncStatus,
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
    if (data.containsKey('card_sync_status')) {
      context.handle(
        _cardSyncStatusMeta,
        cardSyncStatus.isAcceptableOrUnknown(
          data['card_sync_status']!,
          _cardSyncStatusMeta,
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
      cardSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_sync_status'],
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
  final String cardSyncStatus;
  const Student({
    required this.userId,
    this.rfidNumber,
    required this.nama,
    this.nisn,
    this.kelas,
    this.noTelpWali,
    this.syncedAt,
    required this.hikRegistered,
    required this.cardSyncStatus,
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
    map['card_sync_status'] = Variable<String>(cardSyncStatus);
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
      cardSyncStatus: Value(cardSyncStatus),
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
      cardSyncStatus: serializer.fromJson<String>(json['cardSyncStatus']),
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
      'cardSyncStatus': serializer.toJson<String>(cardSyncStatus),
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
    String? cardSyncStatus,
  }) => Student(
    userId: userId ?? this.userId,
    rfidNumber: rfidNumber.present ? rfidNumber.value : this.rfidNumber,
    nama: nama ?? this.nama,
    nisn: nisn.present ? nisn.value : this.nisn,
    kelas: kelas.present ? kelas.value : this.kelas,
    noTelpWali: noTelpWali.present ? noTelpWali.value : this.noTelpWali,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    hikRegistered: hikRegistered ?? this.hikRegistered,
    cardSyncStatus: cardSyncStatus ?? this.cardSyncStatus,
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
      cardSyncStatus: data.cardSyncStatus.present
          ? data.cardSyncStatus.value
          : this.cardSyncStatus,
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
          ..write('hikRegistered: $hikRegistered, ')
          ..write('cardSyncStatus: $cardSyncStatus')
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
    cardSyncStatus,
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
          other.hikRegistered == this.hikRegistered &&
          other.cardSyncStatus == this.cardSyncStatus);
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
  final Value<String> cardSyncStatus;
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
    this.cardSyncStatus = const Value.absent(),
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
    this.cardSyncStatus = const Value.absent(),
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
    Expression<String>? cardSyncStatus,
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
      if (cardSyncStatus != null) 'card_sync_status': cardSyncStatus,
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
    Value<String>? cardSyncStatus,
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
      cardSyncStatus: cardSyncStatus ?? this.cardSyncStatus,
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
    if (cardSyncStatus.present) {
      map['card_sync_status'] = Variable<String>(cardSyncStatus.value);
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
          ..write('cardSyncStatus: $cardSyncStatus, ')
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

class $CardOutboxTable extends CardOutbox
    with TableInfo<$CardOutboxTable, CardOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldRfidMeta = const VerificationMeta(
    'oldRfid',
  );
  @override
  late final GeneratedColumn<String> oldRfid = GeneratedColumn<String>(
    'old_rfid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newRfidMeta = const VerificationMeta(
    'newRfid',
  );
  @override
  late final GeneratedColumn<String> newRfid = GeneratedColumn<String>(
    'new_rfid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    oldRfid,
    newRfid,
    status,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('old_rfid')) {
      context.handle(
        _oldRfidMeta,
        oldRfid.isAcceptableOrUnknown(data['old_rfid']!, _oldRfidMeta),
      );
    }
    if (data.containsKey('new_rfid')) {
      context.handle(
        _newRfidMeta,
        newRfid.isAcceptableOrUnknown(data['new_rfid']!, _newRfidMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      oldRfid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_rfid'],
      ),
      newRfid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_rfid'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $CardOutboxTable createAlias(String alias) {
    return $CardOutboxTable(attachedDatabase, alias);
  }
}

class CardOutboxData extends DataClass implements Insertable<CardOutboxData> {
  final String id;
  final String userId;
  final String? oldRfid;
  final String? newRfid;
  final String status;
  final int attempts;
  final int nextAttemptAt;
  final String? lastError;
  final int createdAt;
  final int? completedAt;
  const CardOutboxData({
    required this.id,
    required this.userId,
    this.oldRfid,
    this.newRfid,
    required this.status,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || oldRfid != null) {
      map['old_rfid'] = Variable<String>(oldRfid);
    }
    if (!nullToAbsent || newRfid != null) {
      map['new_rfid'] = Variable<String>(newRfid);
    }
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  CardOutboxCompanion toCompanion(bool nullToAbsent) {
    return CardOutboxCompanion(
      id: Value(id),
      userId: Value(userId),
      oldRfid: oldRfid == null && nullToAbsent
          ? const Value.absent()
          : Value(oldRfid),
      newRfid: newRfid == null && nullToAbsent
          ? const Value.absent()
          : Value(newRfid),
      status: Value(status),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory CardOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardOutboxData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      oldRfid: serializer.fromJson<String?>(json['oldRfid']),
      newRfid: serializer.fromJson<String?>(json['newRfid']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'oldRfid': serializer.toJson<String?>(oldRfid),
      'newRfid': serializer.toJson<String?>(newRfid),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  CardOutboxData copyWith({
    String? id,
    String? userId,
    Value<String?> oldRfid = const Value.absent(),
    Value<String?> newRfid = const Value.absent(),
    String? status,
    int? attempts,
    int? nextAttemptAt,
    Value<String?> lastError = const Value.absent(),
    int? createdAt,
    Value<int?> completedAt = const Value.absent(),
  }) => CardOutboxData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    oldRfid: oldRfid.present ? oldRfid.value : this.oldRfid,
    newRfid: newRfid.present ? newRfid.value : this.newRfid,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  CardOutboxData copyWithCompanion(CardOutboxCompanion data) {
    return CardOutboxData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      oldRfid: data.oldRfid.present ? data.oldRfid.value : this.oldRfid,
      newRfid: data.newRfid.present ? data.newRfid.value : this.newRfid,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardOutboxData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('oldRfid: $oldRfid, ')
          ..write('newRfid: $newRfid, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    oldRfid,
    newRfid,
    status,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardOutboxData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.oldRfid == this.oldRfid &&
          other.newRfid == this.newRfid &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class CardOutboxCompanion extends UpdateCompanion<CardOutboxData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> oldRfid;
  final Value<String?> newRfid;
  final Value<String> status;
  final Value<int> attempts;
  final Value<int> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<int> rowid;
  const CardOutboxCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.oldRfid = const Value.absent(),
    this.newRfid = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardOutboxCompanion.insert({
    required String id,
    required String userId,
    this.oldRfid = const Value.absent(),
    this.newRfid = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    required int nextAttemptAt,
    this.lastError = const Value.absent(),
    required int createdAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       nextAttemptAt = Value(nextAttemptAt),
       createdAt = Value(createdAt);
  static Insertable<CardOutboxData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? oldRfid,
    Expression<String>? newRfid,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (oldRfid != null) 'old_rfid': oldRfid,
      if (newRfid != null) 'new_rfid': newRfid,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardOutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? oldRfid,
    Value<String?>? newRfid,
    Value<String>? status,
    Value<int>? attempts,
    Value<int>? nextAttemptAt,
    Value<String?>? lastError,
    Value<int>? createdAt,
    Value<int?>? completedAt,
    Value<int>? rowid,
  }) {
    return CardOutboxCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      oldRfid: oldRfid ?? this.oldRfid,
      newRfid: newRfid ?? this.newRfid,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (oldRfid.present) {
      map['old_rfid'] = Variable<String>(oldRfid.value);
    }
    if (newRfid.present) {
      map['new_rfid'] = Variable<String>(newRfid.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardOutboxCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('oldRfid: $oldRfid, ')
          ..write('newRfid: $newRfid, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HikOutboxTable extends HikOutbox
    with TableInfo<$HikOutboxTable, HikOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HikOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeNoMeta = const VerificationMeta(
    'employeeNo',
  );
  @override
  late final GeneratedColumn<String> employeeNo = GeneratedColumn<String>(
    'employee_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oldRfidMeta = const VerificationMeta(
    'oldRfid',
  );
  @override
  late final GeneratedColumn<String> oldRfid = GeneratedColumn<String>(
    'old_rfid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newRfidMeta = const VerificationMeta(
    'newRfid',
  );
  @override
  late final GeneratedColumn<String> newRfid = GeneratedColumn<String>(
    'new_rfid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    employeeNo,
    name,
    oldRfid,
    newRfid,
    operation,
    status,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hik_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<HikOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('employee_no')) {
      context.handle(
        _employeeNoMeta,
        employeeNo.isAcceptableOrUnknown(data['employee_no']!, _employeeNoMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeNoMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('old_rfid')) {
      context.handle(
        _oldRfidMeta,
        oldRfid.isAcceptableOrUnknown(data['old_rfid']!, _oldRfidMeta),
      );
    }
    if (data.containsKey('new_rfid')) {
      context.handle(
        _newRfidMeta,
        newRfid.isAcceptableOrUnknown(data['new_rfid']!, _newRfidMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HikOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HikOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      employeeNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_no'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      oldRfid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_rfid'],
      ),
      newRfid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_rfid'],
      ),
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $HikOutboxTable createAlias(String alias) {
    return $HikOutboxTable(attachedDatabase, alias);
  }
}

class HikOutboxData extends DataClass implements Insertable<HikOutboxData> {
  final String id;
  final String userId;
  final String employeeNo;
  final String? name;
  final String? oldRfid;
  final String? newRfid;
  final String operation;
  final String status;
  final int attempts;
  final int nextAttemptAt;
  final String? lastError;
  final int createdAt;
  final int? completedAt;
  const HikOutboxData({
    required this.id,
    required this.userId,
    required this.employeeNo,
    this.name,
    this.oldRfid,
    this.newRfid,
    required this.operation,
    required this.status,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['employee_no'] = Variable<String>(employeeNo);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || oldRfid != null) {
      map['old_rfid'] = Variable<String>(oldRfid);
    }
    if (!nullToAbsent || newRfid != null) {
      map['new_rfid'] = Variable<String>(newRfid);
    }
    map['operation'] = Variable<String>(operation);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  HikOutboxCompanion toCompanion(bool nullToAbsent) {
    return HikOutboxCompanion(
      id: Value(id),
      userId: Value(userId),
      employeeNo: Value(employeeNo),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      oldRfid: oldRfid == null && nullToAbsent
          ? const Value.absent()
          : Value(oldRfid),
      newRfid: newRfid == null && nullToAbsent
          ? const Value.absent()
          : Value(newRfid),
      operation: Value(operation),
      status: Value(status),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory HikOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HikOutboxData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      employeeNo: serializer.fromJson<String>(json['employeeNo']),
      name: serializer.fromJson<String?>(json['name']),
      oldRfid: serializer.fromJson<String?>(json['oldRfid']),
      newRfid: serializer.fromJson<String?>(json['newRfid']),
      operation: serializer.fromJson<String>(json['operation']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'employeeNo': serializer.toJson<String>(employeeNo),
      'name': serializer.toJson<String?>(name),
      'oldRfid': serializer.toJson<String?>(oldRfid),
      'newRfid': serializer.toJson<String?>(newRfid),
      'operation': serializer.toJson<String>(operation),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  HikOutboxData copyWith({
    String? id,
    String? userId,
    String? employeeNo,
    Value<String?> name = const Value.absent(),
    Value<String?> oldRfid = const Value.absent(),
    Value<String?> newRfid = const Value.absent(),
    String? operation,
    String? status,
    int? attempts,
    int? nextAttemptAt,
    Value<String?> lastError = const Value.absent(),
    int? createdAt,
    Value<int?> completedAt = const Value.absent(),
  }) => HikOutboxData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    employeeNo: employeeNo ?? this.employeeNo,
    name: name.present ? name.value : this.name,
    oldRfid: oldRfid.present ? oldRfid.value : this.oldRfid,
    newRfid: newRfid.present ? newRfid.value : this.newRfid,
    operation: operation ?? this.operation,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  HikOutboxData copyWithCompanion(HikOutboxCompanion data) {
    return HikOutboxData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      employeeNo: data.employeeNo.present
          ? data.employeeNo.value
          : this.employeeNo,
      name: data.name.present ? data.name.value : this.name,
      oldRfid: data.oldRfid.present ? data.oldRfid.value : this.oldRfid,
      newRfid: data.newRfid.present ? data.newRfid.value : this.newRfid,
      operation: data.operation.present ? data.operation.value : this.operation,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HikOutboxData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('employeeNo: $employeeNo, ')
          ..write('name: $name, ')
          ..write('oldRfid: $oldRfid, ')
          ..write('newRfid: $newRfid, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    employeeNo,
    name,
    oldRfid,
    newRfid,
    operation,
    status,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HikOutboxData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.employeeNo == this.employeeNo &&
          other.name == this.name &&
          other.oldRfid == this.oldRfid &&
          other.newRfid == this.newRfid &&
          other.operation == this.operation &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class HikOutboxCompanion extends UpdateCompanion<HikOutboxData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> employeeNo;
  final Value<String?> name;
  final Value<String?> oldRfid;
  final Value<String?> newRfid;
  final Value<String> operation;
  final Value<String> status;
  final Value<int> attempts;
  final Value<int> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<int> rowid;
  const HikOutboxCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.employeeNo = const Value.absent(),
    this.name = const Value.absent(),
    this.oldRfid = const Value.absent(),
    this.newRfid = const Value.absent(),
    this.operation = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HikOutboxCompanion.insert({
    required String id,
    required String userId,
    required String employeeNo,
    this.name = const Value.absent(),
    this.oldRfid = const Value.absent(),
    this.newRfid = const Value.absent(),
    required String operation,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    required int nextAttemptAt,
    this.lastError = const Value.absent(),
    required int createdAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       employeeNo = Value(employeeNo),
       operation = Value(operation),
       nextAttemptAt = Value(nextAttemptAt),
       createdAt = Value(createdAt);
  static Insertable<HikOutboxData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? employeeNo,
    Expression<String>? name,
    Expression<String>? oldRfid,
    Expression<String>? newRfid,
    Expression<String>? operation,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (employeeNo != null) 'employee_no': employeeNo,
      if (name != null) 'name': name,
      if (oldRfid != null) 'old_rfid': oldRfid,
      if (newRfid != null) 'new_rfid': newRfid,
      if (operation != null) 'operation': operation,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HikOutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? employeeNo,
    Value<String?>? name,
    Value<String?>? oldRfid,
    Value<String?>? newRfid,
    Value<String>? operation,
    Value<String>? status,
    Value<int>? attempts,
    Value<int>? nextAttemptAt,
    Value<String?>? lastError,
    Value<int>? createdAt,
    Value<int?>? completedAt,
    Value<int>? rowid,
  }) {
    return HikOutboxCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      employeeNo: employeeNo ?? this.employeeNo,
      name: name ?? this.name,
      oldRfid: oldRfid ?? this.oldRfid,
      newRfid: newRfid ?? this.newRfid,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (employeeNo.present) {
      map['employee_no'] = Variable<String>(employeeNo.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (oldRfid.present) {
      map['old_rfid'] = Variable<String>(oldRfid.value);
    }
    if (newRfid.present) {
      map['new_rfid'] = Variable<String>(newRfid.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HikOutboxCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('employeeNo: $employeeNo, ')
          ..write('name: $name, ')
          ..write('oldRfid: $oldRfid, ')
          ..write('newRfid: $newRfid, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
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
  late final $CardOutboxTable cardOutbox = $CardOutboxTable(this);
  late final $HikOutboxTable hikOutbox = $HikOutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    students,
    tapRecords,
    cardOutbox,
    hikOutbox,
  ];
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
      Value<String> cardSyncStatus,
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
      Value<String> cardSyncStatus,
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

  ColumnFilters<String> get cardSyncStatus => $composableBuilder(
    column: $table.cardSyncStatus,
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

  ColumnOrderings<String> get cardSyncStatus => $composableBuilder(
    column: $table.cardSyncStatus,
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

  GeneratedColumn<String> get cardSyncStatus => $composableBuilder(
    column: $table.cardSyncStatus,
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
                Value<String> cardSyncStatus = const Value.absent(),
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
                cardSyncStatus: cardSyncStatus,
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
                Value<String> cardSyncStatus = const Value.absent(),
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
                cardSyncStatus: cardSyncStatus,
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
typedef $$CardOutboxTableCreateCompanionBuilder =
    CardOutboxCompanion Function({
      required String id,
      required String userId,
      Value<String?> oldRfid,
      Value<String?> newRfid,
      Value<String> status,
      Value<int> attempts,
      required int nextAttemptAt,
      Value<String?> lastError,
      required int createdAt,
      Value<int?> completedAt,
      Value<int> rowid,
    });
typedef $$CardOutboxTableUpdateCompanionBuilder =
    CardOutboxCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> oldRfid,
      Value<String?> newRfid,
      Value<String> status,
      Value<int> attempts,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      Value<int> createdAt,
      Value<int?> completedAt,
      Value<int> rowid,
    });

class $$CardOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $CardOutboxTable> {
  $$CardOutboxTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldRfid => $composableBuilder(
    column: $table.oldRfid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newRfid => $composableBuilder(
    column: $table.newRfid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $CardOutboxTable> {
  $$CardOutboxTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldRfid => $composableBuilder(
    column: $table.oldRfid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newRfid => $composableBuilder(
    column: $table.newRfid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardOutboxTable> {
  $$CardOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get oldRfid =>
      $composableBuilder(column: $table.oldRfid, builder: (column) => column);

  GeneratedColumn<String> get newRfid =>
      $composableBuilder(column: $table.newRfid, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$CardOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardOutboxTable,
          CardOutboxData,
          $$CardOutboxTableFilterComposer,
          $$CardOutboxTableOrderingComposer,
          $$CardOutboxTableAnnotationComposer,
          $$CardOutboxTableCreateCompanionBuilder,
          $$CardOutboxTableUpdateCompanionBuilder,
          (
            CardOutboxData,
            BaseReferences<_$AppDatabase, $CardOutboxTable, CardOutboxData>,
          ),
          CardOutboxData,
          PrefetchHooks Function()
        > {
  $$CardOutboxTableTableManager(_$AppDatabase db, $CardOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> oldRfid = const Value.absent(),
                Value<String?> newRfid = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardOutboxCompanion(
                id: id,
                userId: userId,
                oldRfid: oldRfid,
                newRfid: newRfid,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> oldRfid = const Value.absent(),
                Value<String?> newRfid = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required int nextAttemptAt,
                Value<String?> lastError = const Value.absent(),
                required int createdAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardOutboxCompanion.insert(
                id: id,
                userId: userId,
                oldRfid: oldRfid,
                newRfid: newRfid,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardOutboxTable,
      CardOutboxData,
      $$CardOutboxTableFilterComposer,
      $$CardOutboxTableOrderingComposer,
      $$CardOutboxTableAnnotationComposer,
      $$CardOutboxTableCreateCompanionBuilder,
      $$CardOutboxTableUpdateCompanionBuilder,
      (
        CardOutboxData,
        BaseReferences<_$AppDatabase, $CardOutboxTable, CardOutboxData>,
      ),
      CardOutboxData,
      PrefetchHooks Function()
    >;
typedef $$HikOutboxTableCreateCompanionBuilder =
    HikOutboxCompanion Function({
      required String id,
      required String userId,
      required String employeeNo,
      Value<String?> name,
      Value<String?> oldRfid,
      Value<String?> newRfid,
      required String operation,
      Value<String> status,
      Value<int> attempts,
      required int nextAttemptAt,
      Value<String?> lastError,
      required int createdAt,
      Value<int?> completedAt,
      Value<int> rowid,
    });
typedef $$HikOutboxTableUpdateCompanionBuilder =
    HikOutboxCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> employeeNo,
      Value<String?> name,
      Value<String?> oldRfid,
      Value<String?> newRfid,
      Value<String> operation,
      Value<String> status,
      Value<int> attempts,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      Value<int> createdAt,
      Value<int?> completedAt,
      Value<int> rowid,
    });

class $$HikOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $HikOutboxTable> {
  $$HikOutboxTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeNo => $composableBuilder(
    column: $table.employeeNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldRfid => $composableBuilder(
    column: $table.oldRfid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newRfid => $composableBuilder(
    column: $table.newRfid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HikOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $HikOutboxTable> {
  $$HikOutboxTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeNo => $composableBuilder(
    column: $table.employeeNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldRfid => $composableBuilder(
    column: $table.oldRfid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newRfid => $composableBuilder(
    column: $table.newRfid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HikOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $HikOutboxTable> {
  $$HikOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get employeeNo => $composableBuilder(
    column: $table.employeeNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get oldRfid =>
      $composableBuilder(column: $table.oldRfid, builder: (column) => column);

  GeneratedColumn<String> get newRfid =>
      $composableBuilder(column: $table.newRfid, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$HikOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HikOutboxTable,
          HikOutboxData,
          $$HikOutboxTableFilterComposer,
          $$HikOutboxTableOrderingComposer,
          $$HikOutboxTableAnnotationComposer,
          $$HikOutboxTableCreateCompanionBuilder,
          $$HikOutboxTableUpdateCompanionBuilder,
          (
            HikOutboxData,
            BaseReferences<_$AppDatabase, $HikOutboxTable, HikOutboxData>,
          ),
          HikOutboxData,
          PrefetchHooks Function()
        > {
  $$HikOutboxTableTableManager(_$AppDatabase db, $HikOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HikOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HikOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HikOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> employeeNo = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> oldRfid = const Value.absent(),
                Value<String?> newRfid = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HikOutboxCompanion(
                id: id,
                userId: userId,
                employeeNo: employeeNo,
                name: name,
                oldRfid: oldRfid,
                newRfid: newRfid,
                operation: operation,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String employeeNo,
                Value<String?> name = const Value.absent(),
                Value<String?> oldRfid = const Value.absent(),
                Value<String?> newRfid = const Value.absent(),
                required String operation,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required int nextAttemptAt,
                Value<String?> lastError = const Value.absent(),
                required int createdAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HikOutboxCompanion.insert(
                id: id,
                userId: userId,
                employeeNo: employeeNo,
                name: name,
                oldRfid: oldRfid,
                newRfid: newRfid,
                operation: operation,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HikOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HikOutboxTable,
      HikOutboxData,
      $$HikOutboxTableFilterComposer,
      $$HikOutboxTableOrderingComposer,
      $$HikOutboxTableAnnotationComposer,
      $$HikOutboxTableCreateCompanionBuilder,
      $$HikOutboxTableUpdateCompanionBuilder,
      (
        HikOutboxData,
        BaseReferences<_$AppDatabase, $HikOutboxTable, HikOutboxData>,
      ),
      HikOutboxData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$TapRecordsTableTableManager get tapRecords =>
      $$TapRecordsTableTableManager(_db, _db.tapRecords);
  $$CardOutboxTableTableManager get cardOutbox =>
      $$CardOutboxTableTableManager(_db, _db.cardOutbox);
  $$HikOutboxTableTableManager get hikOutbox =>
      $$HikOutboxTableTableManager(_db, _db.hikOutbox);
}
