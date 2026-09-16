// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  name: json['name'] as String,
  iconCode: json['iconCode'] as String,
  createdDate: _$JsonConverterFromJson<String, DateTime>(
    json['createdDate'],
    const UTCDateTimeConverter().fromJson,
  ),
  colorSchemeName: json['colorSchemeName'] as String?,
  isIncome: json['isIncome'] as bool? ?? false,
)..uuid = json['uuid'] as String;

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'uuid': instance.uuid,
  'createdDate': const UTCDateTimeConverter().toJson(instance.createdDate),
  'name': instance.name,
  'iconCode': instance.iconCode,
  'colorSchemeName': instance.colorSchemeName,
  'isIncome': instance.isIncome,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);
