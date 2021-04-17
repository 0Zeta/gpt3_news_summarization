import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

String openapiKey = "";

Future main() async {
  openapiKey = null;
  try {
    await DotEnv().load('.env');
    openapiKey = DotEnv().env["OPENAI_KEY"];
  } catch(Exception) {}
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
  var phoneOutput = TextEditingController();
  var isLoadingSummarization = false;
  var isLoadingQuizz = false;

  /// The initial promt given to OpenAI
  String prompt = "";

  /// Construct a prompt for OpenAI with the new message and store the response
  void _summarize(String article) async {
    if (article == "") {
      return;
    }

    if (openapiKey == null) {
      _showKeyDialog();
      return;
    }

    /// Enable the loading animation
    setState(() {
      isLoadingSummarization = true;
    });

    /// Continue the prompt template
    prompt =
        "I want to summarize this text:\n###\n$article\n###\nHere is a summary of this text in three short key points that will explain for everyone what the text is about:\n1.";

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
    var transPrompt = "English:\n\"\"\"\n1." +
        summarizationResultBody["choices"][0]["text"] +
        "\n\"\"\"\n###\nHere is the translation of the summary into German:\n\"\"\"\n1.";
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

    var tagsPrompt =
        "Here is a text that I would like you to add tags to for me:\n\"\"\"\n$article\n\"\"\"\nHere are five hashtags:\n\"\"\"";
    var tagsResult = await http.post(
      Uri.parse("https://api.openai.com/v1/engines/davinci/completions"),
      headers: {
        "Authorization": "Bearer $openapiKey",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "prompt": tagsPrompt,
        "temperature": 0.46,
        "max_tokens": 64,
        "top_p": 1,
        "frequency_penalty": 0.5,
        "presence_penalty": 0,
        "stop": ["\"\"\""],
      }),
    );

    phoneOutput.text = "• " + jsonDecode(translationResult.body)["choices"][0]["text"].toString().trim().replaceAll("2.", "•").replaceAll("3.", "•").split("\n\n")[0];
    tagsController.text = jsonDecode(tagsResult.body)["choices"][0]["text"].toString().trim().replaceAll("\n", " ");

    /// Disable the loading animation
    setState(() {
      isLoadingSummarization = false;
    });
  }

  void _showKeyDialog() {
    var keyController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text("Missing API key"),
            content: TextField(
              decoration: InputDecoration(
                hintText: "Please enter your GPT-3 API key.",
              ),
              controller: keyController,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Submit'),
                onPressed: () {
                  setState(() {
                    openapiKey = keyController.text.toString();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        }
    );
  }

  void _quizz(String article) async {
    if (article == "") {
      return;
    }

    if (openapiKey == null) {
      _showKeyDialog();
      return;
    }

    /// Enable the loading animation
    setState(() {
      isLoadingQuizz = true;
    });

    /// Continue the prompt template
    var quizPrompt =
    "Text:\n###\nGeflügelpest im Allgäu: Lindau weist Beobachtungsgebiet aus\nWeil im Nachbarlandkreis Fälle der Geflügelpest registriert wurden, weist Lindau ein Beobachtungsgebiet für die Tierseuche aus. Für Geflügelhalter gelten ab sofort bestimmte Regeln.Nachdem im Bereich der Gemeinde Isny die Geflügelpest ausgebrochen ist, hat der Nachbarlandkreis Lindau nun reagiert und ein sogenanntes \"Beobachtungsgebiet\" ausgewiesen.\n###\nThis is a question about the text and one short answer from the text\n###\nQuestion: \nWo ist die Geflügelpest ausgebrochen?\na) Gemeinde Isny\nb) Japan\nc) Köln\n###\nText:\n###\nIm Mordprozess vor dem Landgericht Regensburg hat der 37-jährige Angeklagte am Donnerstagvormittag gestanden, seine beiden Kinder in Schwarzach im Kreis Straubing-Bogen getötet zu haben.\n###\nThis is a question about the text and one short answer from the text and two wrong options\n###\nQuestion: \nWo hat der Angeklagte seine Kinder getötet?\na) In Schwarzach\nb) In Russland\nc) In Berlin\n###\nText:\n###\nGericht kippt 15-Kilometer-Regel in Bayern\nDie 15-Kilometer-Grenze für Bewohner in Corona-Hotspots gilt in Bayern ab sofort nicht mehr. Der Bayerische Verwaltungsgerichtshof setzte die Regelung im Eilverfahren vorläufig außer Vollzug. Bestätigt wurde indes die FFP2-Maskenpflicht.\n\nDer Bayerische Verwaltungsgerichtshof hat das Verbot von touristischen Tagesausflügen für Bewohner von Corona-Hotspots über einen Umkreis von 15 Kilometern hinaus in Bayern vorläufig gekippt. Die textliche Festlegung eines solchen Umkreises sei nicht deutlich genug und verstoße aller Voraussicht nach gegen den Grundsatz der Normenklarheit, entschied das Gericht am Dienstag.\n\nGegen den Beschluss gibt es keine Rechtsmittel. Der Kläger, der SPD-Landtagsabgeordnete Christian Flisek, erklärte, die Entscheidung zeige, dass auch in Krisenzeiten auf den Rechtsstaat Verlass sei. Künftige Bußgeldbescheide hätten nun keine Rechtsgrundlage mehr - bei Verstößen wurden bisher 500 Euro fällig.\n\n###\nThis is a question about the text and one short answer from the text and two wrong options\n###\nQuestion: \nWelche Strafe gibt es für Verstoße der Regeln?\na) 500 euro\nb) 2000 euro\nc) 15 euro\n###\nText:\n###\n$article\n###\nThis is a question about the text and one short answer from the text and two wrong options\n###\nQuestion: \n";


    var quizzResult = await http.post(
      Uri.parse("https://api.openai.com/v1/engines/davinci/completions"),
      headers: {
        "Authorization": "Bearer $openapiKey",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "prompt": quizPrompt,
        "temperature": 0.6,
        "max_tokens": 166,
        "top_p": 1,
        "frequency_penalty": 0,
        "presence_penalty": 0,
        "stop": ["###"],
      }),
    );
    print(jsonDecode(quizzResult.body));
    phoneOutput.text = jsonDecode(quizzResult.body)["choices"][0]["text"].toString().trim();
    tagsController.text = "";

    /// Disable the loading animation
    setState(() {
      isLoadingQuizz = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// The top app bar with title
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AppBar(
          title: Padding(
            padding: EdgeInsets.only(top: 15, left: 100),
            child: Text(widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                )),
          ),
          centerTitle: false,
        ),
      ),
      body:

          /// The bottom text field
          Container(
              color: Color(0xFFF5F9FF),
              padding:
                  EdgeInsets.only(top: 100, left: 100, right: 100, bottom: 50),
              child: Container(
                  // padding: EdgeInsets.all(10),
                  child: Column(children: [
                Expanded(
                  flex: 8,
                  child: Row(children: [
                    Expanded(
                      flex: 7,
                      child: Column(children: [
                        Expanded(
                          flex: 9,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 50, right: 5),
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
                                _summarize(text);
                              },
                            ),
                          ),
                        ),
                        // )
                        Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.only(bottom: 50),
                                decoration: new BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(50)
                                ),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 1,
                                      child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 30, left: 30),
                                            child: Text(
                                              "Tags:",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                      )
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
                                        ),
                                        controller: tagsController,
                                        enableInteractiveSelection: true,
                                        readOnly: true,
                                        expands: true,
                                        maxLines: null,
                                        textAlignVertical:
                                        TextAlignVertical.top,
                                        decoration: new InputDecoration(
                                          contentPadding: EdgeInsets.only(top: 30),
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
                        )
                      ]),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          child: isLoadingSummarization
                              ? CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Color(0xFF292D3B)),)
                              : ElevatedButton(
                            child: Text('Summarize'),
                            onPressed: () {
                              _summarize(textEditingController.text);
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
                                  color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(15),
                          child: isLoadingQuizz
                              ? CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Color(0xFF292D3B)),)
                              : ElevatedButton(
                            child: Text('Quizz'),
                            onPressed: () {
                              _quizz(textEditingController.text);
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
                                  color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.only(left: 55, right: 100),
                          // constraints: BoxConstraints.expand(),
                          decoration: BoxDecoration(
                              // color: Colors.white,
                              image: DecorationImage(
                            image: AssetImage("assets/images/iphone-xs.png"),
                                alignment: Alignment.centerLeft,
                          )),
                          child: TextField(
                            style: GoogleFonts.zillaSlabHighlight(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              height: 1.5,
                            ),
                            controller: phoneOutput,
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
                        )),
                  ]),
                ),
              ]))),
    );
  }
}
