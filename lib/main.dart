import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlparser;
import 'utils/api.dart';

Future<List<Board>> fetchBoard() async {
  final response = await http
      .get(Uri.parse('https://www.clien.net/service/recommend'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    var bodyHtml = response.body;
    List<Board> lstBoard = [];
    htmlparser.parse(bodyHtml)
        .getElementsByClassName('list_item symph_row')
        .forEach((element) {
          lstBoard.add(
            Board(
              title: element.getElementsByClassName('subject_fixed')[0].text,
              count: element.attributes['data-comment-count'].toString(),
              pageNumber: element.attributes['data-board-sn'].toString(),
            )
          );
    });
    return lstBoard;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load recommend board');
  }
}

Future<Detail> fetchDetail(String pageNumber) async {
  final response = await http
      .get(Uri.parse('https://www.clien.net/service/board/park/' + pageNumber));

  log('pageNumber: $pageNumber');

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    var bodyHtml = response.body;
    List<Board> lstBoard = [];
    String? title = htmlparser.parse(bodyHtml).getElementsByClassName('post_subject')[0].firstChild?.text;
    String? writer = htmlparser.parse(bodyHtml).getElementsByClassName('nickname')[0].firstChild?.text;
    var view = htmlparser.parse(bodyHtml).getElementsByClassName('post_view')[0].innerHtml;

    return Detail(
      title: title.toString(),
      writer: writer.toString(),
      detail: view
    );

  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load recommend board');
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Board>> futureLstBoard;
  late Future<Detail> futureDetail;
  late Widget bodyWidget;

  @override
  void initState() {
    super.initState();
    futureLstBoard = fetchBoard();
    bodyWidget = bodyBoardList();
  }

  Widget bodyBoardList() {
    return Center(
      child: FutureBuilder<List<Board>>(
        future: futureLstBoard,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildList(snapshot.requireData);
          }
          // By default, show a loading spinner.
          return const CircularProgressIndicator();
        },
      ),
    );
  }

  Widget bodyBoardDetail(String pageNumber) {
    return Center(
      child: FutureBuilder<Detail>(
        future: futureDetail,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildDetail(snapshot.requireData);
          }
          // By default, show a loading spinner.
          return const CircularProgressIndicator();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Clien Recommend',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Clien Recommend'),
        ),
        body: bodyWidget,
      ),
    );
  }

  Widget _buildList(List<Board> lstBoard) {

    return ListView.builder(
        itemCount: lstBoard.length,
        itemBuilder: (BuildContext context, int index) {
          return _tile(lstBoard[index].title, lstBoard[index].count, lstBoard[index].pageNumber, Icons.theaters);
        }
      );
  }

  Widget _buildDetail(Detail detail) {

    return SingleChildScrollView(
      child: Html(
        data: detail.detail
      )
    );
  }

  ListTile _tile(String title, String subtitle, String pageNumber, IconData icon) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
          )),
      subtitle: Text(subtitle),
      leading: Icon(
        icon,
        color: Colors.blue[500],
      ),
      onTap: () {
        setState((){
          futureDetail = fetchDetail(pageNumber);
          bodyWidget = bodyBoardDetail(pageNumber);
          log('setState end');
        });
      },
    );
  }
}