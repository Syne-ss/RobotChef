import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/class/elastic_constants.dart';
import 'package:flutter_app/model/model_recipe.dart';
import 'package:elastic_client/console_http_transport.dart';
import 'package:elastic_client/elastic_client.dart' as elastic;
import 'package:flutter_app/screen/detail_screen.dart';
import 'package:flutter_app/class/app_constants.dart';
import 'package:flutter_app/class/db_manager.dart';
import 'package:flutter_app/screen/home_screen.dart';
import 'package:flutter_app/widget/RecipeCard.dart';

class BookmarkScreen extends StatefulWidget {
  _BookmarkScreen createState() => _BookmarkScreen();
}

class _BookmarkScreen extends State<BookmarkScreen> {
  ScrollController _scrollController = ScrollController();
  FocusNode focusNode = FocusNode();

  var _lastRow = 0;
  final fetchRow = 10;
  var stream;
  bool isDisposed = true;

  Future<SearchResult> newStream() async {
    var recipeIdList = await DBManager.getInstance.getAllData(AppConstants.bookmarkDoc);

    final String url = ElasticConstants.endpoint;
    final transport = ConsoleHttpTransport(Uri.parse(url));
    final client = elastic.Client(transport);

    var response;

    response = await client.search(
        'recipe-robotchef', '_doc', createQuery(recipeIdList),
        source: true,
        offset: 0,
        limit: fetchRow * (_lastRow + 1),
        sort: [
          {
            "title.keyword": {"order": "asc"}
          }
        ]).timeout(Duration(seconds: 5));

    await transport.close();

    return response;
  }

  Map<dynamic, dynamic> createQuery(recipeIdList) {
    Map<dynamic, dynamic> query = {
      "bool": {
        "must": [
          {
            "terms": {
              "recipe_id": recipeIdList
            }
          }
        ]
      }
    };

    return query;
  }

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  @override
  void initState() {
    super.initState();
    stream = newStream();
  }

  _BookmarkScreen() {
    _lastRow = 0;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          stream = newStream();
        });
      }
    });
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<SearchResult>(
      stream: Stream.fromFuture(stream),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Icon(Icons.error),
          );
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.hits);
      },
    );
  }

  Widget _buildList(BuildContext context, List<Doc> snapshots) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: snapshots.length,
      itemBuilder: (context, i) {
        final currentRow = (i + 1) ~/ fetchRow;
        if (_lastRow != currentRow) {
          _lastRow = currentRow;
        }
        return _buildListItem(context, snapshots[i]);
      },
      separatorBuilder: (context, i) => Divider(),
    );
  }

  Widget _buildListItem(BuildContext context, Doc data) {
    final recipeData = Recipe.fromMap(data.doc);
    return new RecipeCard(
        recipe: recipeData,
        onTapCard: () {
          Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (BuildContext context) {
                return DetailScreen(recipe: recipeData, onPop: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (BuildContext context) {
                        return this.widget;
                      }));
                },);
              }));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text('즐겨찾기  ', style: TextStyle(color: Colors.white)),
              leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (BuildContext context) {
                          return HomeScreen();
                        }));
                  }),
              iconTheme: IconThemeData(color: Colors.white)),
        body: Container(
            child: Column(
          children: <Widget>[
            Expanded(child: _buildBody(context)),
          ],
        )));
  }
}
