import 'dart:convert';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
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
      home: MyHomePage(title: "NEWS SUMMARIZER"),
      theme: ThemeData(
        primaryColor: Color(0xFF292D3B),
        scaffoldBackgroundColor: Color(0xFFF5F9FF),
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
  var tagsController = TextEditingController();
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
    var summarizationResult = await http.post(
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
    var summarizationResultBody = jsonDecode(summarizationResult.body);
    var transPrompt = "English:\n\"\"\"\n1." + summarizationResultBody["choices"][0]["text"] + "\n\"\"\"\n###\nHere is the translation of the summary into German:\n\"\"\"\n1.";
    print(transPrompt);
    var translationResult = await http.post(
      Uri.parse("https://api.openai.com/v1/engines/davinci/completions"),
      headers: {
        "Authorization": "Bearer $openapiKey",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "prompt": transPrompt,
        "temperature": 0.1,
        "max_tokens": 100,
        "top_p": 0.9,
        "frequency_penalty": 0.2,
        "presence_penalty": 0.1,
        "stop": ["###", "\"\"\""],
      }),
    );



    var resultSummarizationText = "1." + jsonDecode(translationResult.body)["choices"][0]["text"];

    var tagsPrompt = "$resultSummarizationText\n###\nHere are three important keywords of the summary that will explain for everyone what the text is about:";
    var tagsResult = await http.post(
      Uri.parse("https://api.openai.com/v1/engines/davinci/completions"),
      headers: {
        "Authorization": "Bearer $openapiKey",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "prompt": tagsPrompt,
        "temperature": 0.1,
        "max_tokens": 100,
        "top_p": 0.9,
        "frequency_penalty": 0.2,
        "presence_penalty": 0.1,
        "stop": ["###", "\"\"\""],
      }),
    );
    resultSummarization.text = resultSummarizationText;
    tagsController.text = "1." + jsonDecode(tagsResult.body)["choices"][0]["text"];

    /// Disable the loading animation
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// The top app bar with title
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AppBar(
        title:  Padding(
          padding: EdgeInsets.only(top:15, left: 100),
          child: Text(widget.title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30,
              )),
        ),
        centerTitle: false,

      ),),
      body:

          /// The bottom text field
          Container(
              color: Color(0xFFF5F9FF),
              padding: EdgeInsets.only(top:100, left: 100, right: 100, bottom: 50),
              child: Container(
                  // padding: EdgeInsets.all(10),
                  child: Column(children: [
                    Expanded(
                      flex: 8,
                      child: Row(children: [
                        Expanded(
                          flex: 7,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 50),
                            // color: Colors.white,
                            child: TextField(
                              textAlignVertical: TextAlignVertical.top,
                              controller: textEditingController,
                              expands: true,
                              maxLines: null,
                              decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: EdgeInsets.all(35),
                                  border: new OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(50.0),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Enter the article here.'),
                              onSubmitted: (text) {
                                sendArticle(text);
                              },
                            ),
                          ),
                        ),
                        Container(
                              padding: EdgeInsets.all(15),
                              child: isLoading
                                  ? CircularProgressIndicator()
                                  : ElevatedButton(

                                child: Text('Summarize'),
                                onPressed: () {
                                  sendArticle(textEditingController.text);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: new RoundedRectangleBorder(
                                    borderRadius: new BorderRadius.circular(30.0),
                                  ),
                                  primary: Color(0xFF292D3B),
                                  onPrimary: Colors.white,
                                  shadowColor: Colors.grey.shade500,
                                  elevation: 20,
                                  padding: EdgeInsets.all(25),
                                  textStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20
                                  ),
                                ),
                              ),
                            ),

                        Expanded(
                          flex: 3,
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
                            padding: EdgeInsets.all(100),
                            // constraints: BoxConstraints.expand(),
                            decoration: BoxDecoration(
                                // color: Colors.white,
                                image: DecorationImage(
                                    image: AssetImage("assets/images/iphone-xs.png"),
                                    )
                            ),
                            child: TextField(
                                  style: GoogleFonts.architectsDaughter(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    height: 1.5,
                                  ),
                                  controller: resultSummarization,
                                  enableInteractiveSelection: true,
                                  readOnly: true,
                                  expands: true,
                                  maxLines: null,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: new InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                  ),
                                ),
                            )
                        ),
                      ]),
                    ),
                    // Align(
                    //   alignment: Alignment.bottomRight,
                    //   child: Container(
                    //     padding: EdgeInsets.all(15),
                    //     child: isLoading
                    //         ? CircularProgressIndicator()
                    //         : ElevatedButton.icon(
                    //       label: Text('Summarize'),
                    //       icon: Icon(Icons.fast_forward_outlined),
                    //       onPressed: () {
                    //         sendArticle(textEditingController.text);
                    //       },
                    //     ),
                    //   ),
                    // )
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.topLeft,
                                  child: Text(
                                "Tags:",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))
                          ),
                          Expanded(
                            flex: 9,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: TextField(
                                style: GoogleFonts.openSans(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  height: 1.5,
                                ),
                                controller: tagsController,
                                enableInteractiveSelection: true,
                                readOnly: true,
                                expands: true,
                                maxLines: null,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: new InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          )
                        ],
                      )

                    )
                  ]))),
    );
  }
}


