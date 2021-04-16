import 'dart:convert';
import 'dart:ui' as ui show Image;

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
      title: 'GPT-3 News Summarizer',
      home: MyHomePage(title: "GPT-3 News Summarizer"),
      theme: ThemeData(
        primaryColor: Colors.blue.shade600,
        scaffoldBackgroundColor: Colors.grey.shade800,
      ),
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

    /// Enable the loading animation
    setState(() {
      isLoading = true;
    });

    /// Continue the prompt template
    prompt = "I want to summarize this text:\n###\n$article\n###\nHere is a summary of this text in three short key points that will explain for everyone what the text is about:\n1.";

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
        "max_tokens": 100,
        "top_p": 0.9,
        "frequency_penalty": 0.2,
        "presence_penalty": 0.1,
        "stop": "###",
      }),
    );

    /// Decode the body and select the first choice
    var body = jsonDecode(result.body);
    var text = "English:\n\"\"\"\n1." + body["choices"][0]["text"] + "\n\"\"\"\n###\nHere is the translation of the summary into German:\n\"\"\"\n1.";
    print(text);
    result = await http.post(
      Uri.parse("https://api.openai.com/v1/engines/davinci/completions"),
      headers: {
        "Authorization": "Bearer $openapiKey",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "prompt": text,
        "temperature": 0.1,
        "max_tokens": 100,
        "top_p": 0.9,
        "frequency_penalty": 0.2,
        "presence_penalty": 0.1,
        "stop": ["###", "\"\"\""],
      }),
    );
    text = "1." + jsonDecode(result.body)["choices"][0]["text"];

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
              color: Colors.grey.shade800,
              padding: EdgeInsets.all(10),
              child: Container(
                  // padding: EdgeInsets.all(10),
                  child: Column(children: [
                    Expanded(
                      flex: 3,
                      child: Row(children: [
                        Expanded(
                          flex: 7,
                          child: Container(
                            margin: EdgeInsets.all(10),
                            color: Colors.white,
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
                          // child: Container(
                          //   color: Colors.white,
                          //   margin: EdgeInsets.all(15),
                          //   child: TextField(
                          //     textAlignVertical: TextAlignVertical.top,
                          //     controller: resultSummarization,
                          //     enableInteractiveSelection: true,
                          //     readOnly: true,
                          //     expands: true,
                          //     maxLines: null,
                          //     decoration: InputDecoration(
                          //       focusColor: Theme.of(context).focusColor,
                          //       border: OutlineInputBorder(),
                          //     ),
                          //   ),
                          // ) ,
                          child:  Container(
                            width: 762,
                            height: 1489,
                            padding: EdgeInsets.all(45),
                            // constraints: BoxConstraints.expand(),
                            decoration: BoxDecoration(
                                // color: Colors.white,
                                image: DecorationImage(
                                    image: AssetImage("assets/images/iphone.png"),
                                    )
                            ),
                            child: TextField(
                                  style: TextStyle(color: Colors.white),
                                  controller: resultSummarization,
                                  enableInteractiveSelection: true,
                                  readOnly: true,
                                  expands: true,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    // focusColor: Theme.of(context).focusColor,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                            )
                        ),
                      ]),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: EdgeInsets.all(15),
                        child: isLoading
                            ? CircularProgressIndicator()
                            : ElevatedButton.icon(
                          label: Text('Summarize'),
                          icon: Icon(Icons.fast_forward_outlined),
                          onPressed: () {
                            sendArticle(textEditingController.text);
                          },
                        ),
                      ),
                    )

                  ]))),
    );
  }
}


