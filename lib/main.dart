// Import MaterialApp and other widgets which we can use to quickly create a material app
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:core';

void main() => runApp(new AppMain());

class AppMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'SimpleMemo',
        home: new MemoList()
    );
  }
}

class MemoItem {
  String _title;
  String _body;
  String _saveKey;

  MemoItem(String key, String text) {
    this._body = text;
    this._title = text.split('\n')[0];
    this._saveKey  = key;
  }

  String title(){
    return this._title;
  }

  String body(){
    return this._body;
  }

  String key(){
    return this._saveKey;
  }
}

class MemoList extends StatefulWidget {
  @override
  createState() => new MemoListState();
}

class MemoListState extends State<MemoList> {
  List<MemoItem> _memoItems = [];
  String latestInput = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for(var key in prefs.getKeys()){
      _memoItems.add(new MemoItem(key, prefs.getString(key)));
    }
  }

  // Instead of auto generating a todo item, _addMemoItem now accepts a string
  void _addMemoItem(String body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Putting our code inside "setState" tells the app that our state has changed,
    // and it will automatically re-render the list
    //             ^^^^^^^^^^^^^^^^^^^^^^^
    // ==> calling setState() to invoke MemoList.createState(),
    //     and that cause re-render
    if( body.length > 0 ){
      setState( () {
        var item = new MemoItem(DateTime.now().toString(), body);
        _memoItems.add(item);
        prefs.setString(item.key(), item.body());
      });
    }
  }

  // Much like _addMemoItem, this modifies the array of todo strings and
  // notifies the app that the state has changed by using setState
  void _removeMemoItem(int index) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var target = _memoItems[index];
    setState( () => _memoItems.removeAt(index));
    await prefs.remove(target.title());
  }


  void _promptRemoveTodoItem(int index){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text('Delete Memo "${_memoItems[index].title()}" ??'),

              actions: <Widget>[
                new FlatButton(
                    child: new Text('CANCEL'),
                    onPressed: () => Navigator.of(context).pop()
                ),

                new FlatButton(
                    child: new Text('Delete'),
                    onPressed: (){
                      _removeMemoItem(index);
                      Navigator.of(context).pop();
                    }
                ),
              ]
          );
        }
    );
  }

  // Build the whole list of todo items
  Widget _buildTodoList() {
    return new ListView.builder(
      // itemBuilder will be automatically be called as many times as it takes
      // for the list to fill up its available space, which is most likely
      // more than the number of todo items we have.
      // So, we need to check the index is OK.
      // ignore: missing_return
      itemBuilder: (context, index) {
        if(index < _memoItems.length){
          return _buildTodoItem(_memoItems[index].title(), index);
        }
      },
    );
  }

  // Build a single todo item
  Widget _buildTodoItem(String todoText, int index){
    return new ListTile(
        title: new Text(todoText),
        onTap: () => _promptRemoveTodoItem(index)
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text('Memo')
      ),

      body: _buildTodoList(),

      floatingActionButton: new FloatingActionButton(
        // pressing this button now opens the new screen
          onPressed: _pushAddMemoScreen,
          tooltip: 'Add Memo',
          child: new Icon(Icons.add)
      ),
    );
  }

  Widget _generateMemoRegisterInput(BuildContext context) {
    return new Scaffold(
      body: new TextField(
        autofocus: true,
        keyboardType: TextInputType.multiline,
        maxLines: null,

        onChanged: (text) {
          this.latestInput = text;
        },

        decoration: new InputDecoration(
            hintText: 'Enter something ...',
            contentPadding: const EdgeInsets.all(16.0)
        ),
      ),

      floatingActionButton: new FloatingActionButton(
          onPressed: (){
            Navigator.pop(context); // Close the add todo screen
            _addMemoItem(this.latestInput);
          },
          tooltip: 'Register Memo',
          child: new Icon(Icons.add)
      ),
    );
  }

  // MaterialPageRoute will automatically animate the screen entry,
  // as well as adding a back button to close it
  MaterialPageRoute _generateMemoRegisterView(BuildContext context) {
    var page = new MaterialPageRoute(
          builder: (context) {
            return new Scaffold(
              appBar: new AppBar(
                  title: new Text('Add new Memo')
              ),
              body: _generateMemoRegisterInput(context),
            );
          }
        );
    return page;
  }

  void _pushAddMemoScreen() {
    // Push this page onto the stack
    Navigator.of(context).push(
      _generateMemoRegisterView(context)
    );
  }

}
