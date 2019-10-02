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

