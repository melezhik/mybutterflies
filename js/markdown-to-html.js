function parse_markdown () {

    var markdown = document.getElementById("markdown").innerText;
    // alert(markdown)
    // var hljs = require('highlight.js'); // https://highlightjs.org/ 
    var md = window.markdownit({
      html: false,
      breaks: false,
      linkify: true,
      typographer: true,
      langPrefix:   'language-',
      highlight: function (str, lang) {
      if (lang && hljs.getLanguage(lang)) {
          try {
            return '<pre class="hljs"><code>' +
                   hljs.highlight(lang, str, true).value +
                   '</code></pre>';
          } catch (__) {}
        }

        return '<pre class="hljs"><code>' + md.utils.escapeHtml(str) + '</code></pre>';
      }

    });;
    var html = md.render(markdown);
    // alert(html);
    document.getElementById("markdown").innerHTML = "";
    document.getElementById("doc").innerHTML = html;

}

