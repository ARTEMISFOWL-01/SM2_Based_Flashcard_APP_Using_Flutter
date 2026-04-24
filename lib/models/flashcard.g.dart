// GENERATED CODE - DO NOT MODIFY BY HAND
// Updated manually to include SM-2 fields (easeFactor, repetitions)

part of 'flashcard.dart';

// **************************************************************************

// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 1;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Flashcard(
      id: fields[0] as String,
      question: fields[1] as String,
      answer: fields[2] as String,
      interval: fields[3] as int,
      nextReview: fields[4] as DateTime?,
      correctCount: fields[5] as int,
      easeFactor: fields[6] != null ? (fields[6] as num).toDouble() : 2.5,
      repetitions: fields[7] != null ? fields[7] as int : 0,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.answer)
      ..writeByte(3)
      ..write(obj.interval)
      ..writeByte(4)
      ..write(obj.nextReview)
      ..writeByte(5)
      ..write(obj.correctCount)
      ..writeByte(6)
      ..write(obj.easeFactor)
      ..writeByte(7)
      ..write(obj.repetitions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
