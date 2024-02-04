import 'package:flutter/material.dart';
import 'package:info_projekt/services/remote_services.dart';
import 'package:info_projekt/models/news.dart';
import 'package:url_launcher/url_launcher.dart';

//This class shows the newpage

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPage();
}

class _NewsPage extends State<NewsPage> {
  List<News>? newsArticles;
  bool contentLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchNewsArticles();
  }

  fetchNewsArticles() async {
    newsArticles = await RemoteService().getNews();
    if (newsArticles != null) {
      setState(() {
        contentLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock News'),
        backgroundColor: const Color.fromRGBO(126, 192, 238, 1),
      ),
      body: contentLoaded
          ? ListView.builder(
              itemCount: newsArticles?.length ?? 0,
              itemBuilder: (context, index) {
                final article = newsArticles![index];
                return ListTile(
                  onTap: () => launchUrl(article.url),
                  title: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: article.image != null
                              ? Image.network(article.image!)
                              : Container(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //Title with max number of lines = 2
                              Text(
                                article.title,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              //text of the news with max number of lines = 4
                              Text(
                                article.text,
                                style: const TextStyle(fontSize: 15),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Read more...',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true, enableJavaScript: true);
    } else {
      throw 'Could not launch $url';
    }
  }
}
