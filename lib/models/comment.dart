import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable()
class CommentModel {
  final String productId;
  final String userId;
  final String userName;
  final String content;

  CommentModel({
    required this.productId,
    required this.userId,
    required this.userName,
    required this.content,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);
}
