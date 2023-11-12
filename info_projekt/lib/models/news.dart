// To parse this JSON data, do
//
//     final post = postFromJson(jsonString);

import 'dart:convert';

List<News> postFromJson(String str) =>
    List<News>.from(json.decode(str).map((x) => News.fromJson(x)));

String postToJson(List<News> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class News {
  String? category;
  int datetime;
  String headline;
  int id;
  String? image;
  String? related;
  String source;
  String summary;
  String url;

  News({
    this.category,
    required this.datetime,
    required this.headline,
    required this.id,
    this.image,
    this.related,
    required this.source,
    required this.summary,
    required this.url,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
        category: json["category"],
        datetime: json["datetime"],
        headline: json["headline"],
        id: json["id"],
        image: json["image"],
        related: json["related"],
        source: json["source"],
        summary: json["summary"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "category": category,
        "datetime": datetime,
        "headline": headline,
        "id": id,
        "image": image,
        "related": related,
        "source": source,
        "summary": summary,
        "url": url,
      };
}
