import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String OPENAI_KEY = "";

Future main() async {
  await DotEnv().load('.env');
  OPENAI_KEY = DotEnv().env["OPENAI_KEY"];
  runApp(GPTSummarizer());

}

class GPTSummarizer extends StatelessWidget {

  void _handleButton() {

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPT News summarizer',
      home: Scaffold(
        appBar: AppBar(
          title: Text('GPT News summarizer'),
        ),
        body: Container(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          textAlignVertical: TextAlignVertical.top,
                          expands: true,
                          maxLines: null,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter the article'
                          ),
                        ),
                      ),
                      Expanded(
                          child: Center(child: Text("Test"))
                      ),
                    ]
                ),
              ),
              Expanded(
                  child: Center(
                    child: RaisedButton(onPressed: _handleButton)
              ),
              ),
            ]
          )
        )
      ),
    );
  }
}