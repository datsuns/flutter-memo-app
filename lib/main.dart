// Import MaterialApp and other widgets which we can use to quickly create a material app
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' as foundation;
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

  String toTitle(String base) {
    return base.split('\n')[0];
  }

  MemoItem(String key, String text) {
    this._body = text;
    this._title = this.toTitle(text);
    this._saveKey  = key;
  }

  void overwrite(String text) {
    this._body = text;
    this._title = this.toTitle(text);
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

  void dump(){
    print('     title[${this.title()}]');
    print('       key[${this.key()}]');
    print('      body[[${this.body()}]]');
  }
}

class MemoList extends StatefulWidget {
  @override
  createState() => new MemoListState();
}

class MemoListState extends State<MemoList> {
  List<MemoItem> _memoItems = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for(var key in prefs.getKeys()){
      this._memoItems.add(new MemoItem(key, prefs.getString(key)));
    }
  }

  // Instead of auto generating a memo item, _addMemoItem now accepts a string
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
        this._memoItems.add(item);
        prefs.setString(item.key(), item.body());
      });
    }
  }

  // Much like _addMemoItem, this modifies the array of memo strings and
  // notifies the app that the state has changed by using setState
  void _removeMemoItem(int index) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var target = this._memoItems[index];
    setState( () => this._memoItems.removeAt(index));
    await prefs.remove(target.key());
  }

  void _updateMemoItem(int index, String body) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var target = this._memoItems[index];
    setState( () => target.overwrite(body) );
    prefs.setString(target.key(), target.body());
  }

  void _promptRemoveMemoItem(int index){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text('Delete Memo "${this._memoItems[index].title()}" ??'),
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

  void _memoEditAction(int index){
    Navigator.of(context).push(
        _generateMemoEditView(context, index)
    );
  }

  // Build the whole list of memo items
  Widget _buildMemoList() {
    return new ListView.builder(
      // itemBuilder will be automatically be called as many times as it takes
      // for the list to fill up its available space, which is most likely
      // more than the number of memo items we have.
      // So, we need to check the index is OK.
      // ignore: missing_return
      itemBuilder: (context, index) {
        if(index < this._memoItems.length){
          return _buildMemoItem(this._memoItems[index].title(), index);
        }
      },
    );
  }

  // Build a single memo item
  Widget _buildMemoItem(String text, int index){
    return new ListTile(
      title: new Text(text),
      onTap: () => _memoEditAction(index),
      onLongPress: () => _promptRemoveMemoItem(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    var footer = foundation.kReleaseMode ? null : <Widget>[
        new FlatButton(
          onPressed: _debugDumpMemoItems,
          child: new Text('dump-cur'),
        ),
        new FlatButton(
          onPressed: _debugDumpSavedItems,
          child: new Text('dump-saved'),
        ),
      ];

    return new Scaffold(
      appBar: new AppBar(
          title: new Text('Memo')
      ),
      body: _buildMemoList(),
      persistentFooterButtons: footer,
      floatingActionButton: new FloatingActionButton(
        // pressing this button now opens the new screen
          onPressed: _pushAddMemoScreen,
          tooltip: 'Add Memo',
          child: new Icon(Icons.add)
      ),
    );
  }

  Widget _generateMemoRegisterInput(BuildContext context) {
    TextEditingController controller = new TextEditingController(text: "");
    return new Scaffold(
      body: new TextField(
        autofocus:    true,
        keyboardType: TextInputType.multiline,
        maxLines:     null,
        controller:   controller,

        decoration: new InputDecoration(
            hintText: 'Enter something ...',
            contentPadding: const EdgeInsets.all(16.0)
        ),
      ),

      floatingActionButton: new FloatingActionButton(
          onPressed: (){
            Navigator.pop(context); // Close the add memo screen
            _addMemoItem(controller.text);
          },
          tooltip: 'Register Memo',
          child: new Icon(Icons.check)
      ),
    );
  }

  Widget _generateMemoEditInput(BuildContext context, int index) {
    var target = this._memoItems[index];
    TextEditingController controller = new TextEditingController(text: target.body());
    return new Scaffold(
      body: new TextField(
        autofocus:    true,
        keyboardType: TextInputType.multiline,
        maxLines:     null,
        controller:   controller,
      ),

      floatingActionButton: new FloatingActionButton(
          onPressed: (){
            Navigator.pop(context); // Close the add memo screen
            _updateMemoItem(index, controller.text);
          },
          tooltip: 'Update Memo',
          child: new Icon(Icons.check)
      ),
    );
  }

  MaterialPageRoute _generateMaterialPageWith(BuildContext context, Scaffold s) {
    return new MaterialPageRoute(
        builder: (context) => s
    );
  }

  // MaterialPageRoute will automatically animate the screen entry,
  // as well as adding a back button to close it
  MaterialPageRoute _generateMemoRegisterView(BuildContext context) {
    return _generateMaterialPageWith(context, new Scaffold(
      appBar: new AppBar(title: new Text('Add new Memo')),
      body:   _generateMemoRegisterInput(context),
    )
    );
  }

  MaterialPageRoute _generateMemoEditView(BuildContext context, int index) {
    return _generateMaterialPageWith(context, new Scaffold(
      appBar: new AppBar(title: new Text('Edit Memo')),
      body:   _generateMemoEditInput(context, index),
    )
    );
  }

  void _pushAddMemoScreen() {
    // Push this page onto the stack
    Navigator.of(context).push(
        _generateMemoRegisterView(context)
    );
  }

  void _debugDumpMemoItems() {
    print('[${this._memoItems.length}] items.');
    for(var i = 0; i < this._memoItems.length; i++ ){
      print('  [${i}]');
      this._memoItems[i].dump();
    }
  }

  void _debugDumpSavedItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var keys = prefs.getKeys();
    print('[${keys.length}] items saved');
    for( var k in prefs.getKeys() ) {
      print('-- key[${k}] --');
      print('  body[${prefs.getString(k)}] --');
    }
  }
}
