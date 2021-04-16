import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

String openapiKey = "";

Future main() async {
  await DotEnv().load('.env');
  openapiKey = DotEnv().env["OPENAI_KEY"];
  runApp(GPTSummarizer());
}

class GPTSummarizer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPT-3 News summarizer',
      home: MyHomePage(title: "GPT-3 News summarizer"),
      theme: ThemeData.light(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();

  static _MyHomePageState of(BuildContext context) {
    return context.findAncestorStateOfType();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var textEditingController = TextEditingController();
  var resultSummarization = TextEditingController();
  var isLoading = false;

  /// The initial promt given to OpenAI
  String prompt = "";

  /// Construct a prompt for OpenAI with the new message and store the response
  void sendArticle(String article) async {
    print(article);
    if (article == "") {
      return;
    }

    /// Reset the text input
    textEditingController.text = "";

    /// Enable the loading animation
    setState(() {
      isLoading = true;
    });

    /// Continue the prompt template
    prompt = "$article"
        "\n"
        "one-sentence summary:";

    /// Make the api request to OpenAI
    /// See available api parameters here: https://beta.openai.com/docs/api-reference/completions/create
    var result = await http.post(
      Uri.parse("https://api.openai.com/v1/engines/davinci/completions"),
      headers: {
        "Authorization": "Bearer $openapiKey",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "prompt": prompt,
        "temperature": 0.2,
        "max_tokens": 10,
        "top_p": 0.8,
        "frequency_penalty": 0.2,
        "presence_penalty": 0.1,
        "stop": "",
      }),
    );

    /// Decode the body and select the first choice
    var body = jsonDecode(result.body);
    var text = body["choices"][0]["text"];
    print(text);

    resultSummarization.text = text;

    /// Disable the loading animation
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// The top app bar with title
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body:

          /// The bottom text field
          Container(
              color: Theme.of(context).backgroundColor,
              padding: EdgeInsets.all(15),
              child: Container(
                  padding: EdgeInsets.all(40),
                  child: Column(children: [
                    Expanded(
                      flex: 3,
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            margin: EdgeInsets.all(15),
                            color: Theme.of(context).primaryColorLight,
                            child: TextField(
                              textAlignVertical: TextAlignVertical.top,
                              controller: textEditingController,
                              expands: true,
                              maxLines: null,
                              decoration: InputDecoration(
                                  focusColor: Theme.of(context).focusColor,
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter the article here.'),
                              onSubmitted: (text) {
                                sendArticle(text);
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: EdgeInsets.all(15),
                            child: TextField(
                              textAlignVertical: TextAlignVertical.top,
                              controller: resultSummarization,
                              enableInteractiveSelection: true,
                              readOnly: true,
                              expands: true,
                              maxLines: null,
                              decoration: InputDecoration(
                                focusColor: Theme.of(context).focusColor,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 35, bottom: 20),
                      child: isLoading
                          ? CircularProgressIndicator()
                          : IconButton(
                              icon: Icon(
                                Icons.send,
                                size: 35,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {
                                sendArticle(textEditingController.text);
                              },
                            ),
                    ),
                  ]))),
    );
  }
}
