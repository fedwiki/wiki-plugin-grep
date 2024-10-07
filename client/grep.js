/*
 * Federated Wiki : Grep Plugin
 *
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-plugin-grep/blob/master/LICENSE.txt
 */

const escape = (line) => {
  return line
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
};

const word = (string) => {
  if (!string.match(/^[a-z]*$/)) {
    throw new Error(`expecting type for '${string}'`);
  }
  return string;
};

const parse = (text) => {
  const program = [];
  const listing = [];
  let errors = 0;
  for (const line of text.split("\n")) {
    let html = escape(line);
    try {
      const [, op, arg] = line.match(/^\s*(\w*)\s*(.*)$/);
      switch (op) {
        case '':
          break;
        case 'ITEM':
        case 'ACTION':
          program.push({ op, type: word(arg) });
          break;
        case 'TEXT':
        case 'TITLE':
        case 'SITE':
        case 'ID':
        case 'ALIAS':
        case 'JSON':
          program.push({ op, regex: new RegExp(arg, 'mi') });
          break;
        default:
          throw new Error(`don't know '${op}' command`);
      }
    } catch (err) {
      errors++;
      html = `<span style="background-color:#fdd;width:100%;" title="${err.message}">${html}</span>`;
    }
    listing.push(html);
  }
  return [program, listing.join('<br>'), errors];
};

const evalPage = (page, steps, count) => {
  if (count >= steps.length) return true;
  const step = steps[count];
  switch (step.op) {
    case 'ITEM':
      count++;
      for (const item of page.story || []) {
        if (step.type === '' || item.type === step.type) {
          if (evalPart(item, steps, count)) return true;
        }
      }
      return false;
    case 'ACTION':
      count++;
      for (const action of page.journal || []) {
        if (step.type === '' || action.type === step.type) {
          if (evalPart(action, steps, count)) return true;
        }
      }
      return false;
    default:
      return evalPart(page, steps, count);
  }
};

const evalPart = (part, steps, count) => {
  if (count >= steps.length) return true;
  const step = steps[count++];
  switch (step.op) {
    case 'TEXT':
    case 'TITLE':
    case 'SITE':
    case 'ID':
    case 'ALIAS':
      const key = step.op.toLowerCase();
      if ((part[key] || part.item?.[key] || '').match(step.regex)) return true;
    case 'JSON':
      const json = JSON.stringify(part, null, ' ');
      if (json.match(step.regex)) return true;
    default:
      return false;
  }
};

const run = ($item, program) => {
  const status = (text) => {
    $item.find('.caption').text(text);
  };

  const want = (page) => {
    return evalPage(page, program, 0);
  };

  status("fetching sitemap");
  // this should change to use the site adapter
  $.getJSON(`//${location.host}/system/sitemap.json`, (sitemap) => {
    let checked = 0;
    let found = 0;
    for (const place of sitemap) {
      // this should change to use the site adapter
      $.getJSON(`//${location.host}/${place.slug}.json`, (page) => {
        const text = `[[${page.title}]] (${page.story.length})`;
        if (want(page)) {
          found++;
          $item.find('.result').append(`${wiki.resolveLinks(text)}<br>`);
        }
        checked++;
        let report = `found ${found} pages of ${checked} checked`;
        if (checked < sitemap.length) report += `, ${sitemap.length - checked} remain`;
        status(report);
      });
    }
  });
};

const emit = ($item, item) => {
  const [program, listing, errors] = parse(item.text);
  const caption = errors ? `${errors} errors` : 'ready';
  $item.append(`
    <div style="background-color:#eee;padding:15px;">
      <div style="text-align:center">
        <div class=listing>${listing} <a class=open href='#'>»</a></div>
        <button>find</button>
        <p class="caption">${caption}</p>
      </div>
      <p class="result"></p>
    </div>
  `);
};

const open_all = (this_page, titles) => {
  for (const title of titles) {
    wiki.doInternalLink(title, this_page);
    this_page = null;
  }
};

const bind = ($item, item) => {
  $item.on('dblclick', () => wiki.textEditor($item, item));
  $item.find('button').on('click', (e) => {
    const [program, , errors] = parse(item.text);
    if (!errors) run($item, program);
  });
  $item.find('a.open').on('click', (e) => {
    e.stopPropagation();
    e.preventDefault();
    const this_page = e.shiftKey ? null : $item.parents('.page');
    open_all(this_page, $item.find('a.internal').map(function () { return $(this).text(); }));
  });
};

if (typeof window !== 'undefined') {
  window.plugins.grep = { emit, bind };
}

if (typeof module !== 'undefined') {
  module.exports = { parse, evalPart, evalPage };
}
