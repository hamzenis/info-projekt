import 'dart:convert';

List<News> postFromJson(String str) =>
    List<News>.from(json.decode(str).map((x) => News.fromJson(x)));

String postToJson(List<News> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

//late-Stichwort: Variablen werden hier nicht initialisiert
class News {
  String? symbol;
  String publishedDate;
  String title;
  String? image;
  String site;
  String text;
  String url;

  News({
    this.symbol,
    required this.publishedDate,
    required this.title,
    this.image,
    required this.site,
    required this.text,
    required this.url,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
        symbol: json["symbol"],
        publishedDate: json["publishedDate"],
        title: json["title"],
        image: json["image"],
        site: json["site"],
        text: json["text"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "symbol": symbol,
        "publishedDate": publishedDate,
        "title": title,
        "image": image,
        "site": site,
        "text": text,
        "url": url,
      };
}
