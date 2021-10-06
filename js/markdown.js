function parse_markdown () {
    var markdown = document.getElementById("markdown").innerHTML;

    // alert(markdown);
    document.getElementById("data").innerHTML = marked(
      markdown,
      {

        highlight: function(code, lang) {
          // const hljs = require('highlight.js');
          // alert("OK")
          const language = hljs.getLanguage(lang) ? lang : 'plaintext';
          // alert(language + '\n' + code);
          return hljs.highlight(code, { language:  language }).value;
        },

        langPrefix: 'hljs language-', // highlight.js css expects a top-level 'hljs' class.

        pedantic: false,
        gfm: true,
        breaks: false,
        sanitize: false,
        smartLists: true,
        smartypants: false,
        xhtml: false

      }
    );
}

