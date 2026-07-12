// Client-side search over Zola's elasticlunr index, man -k style.
// The index (search_index.en.js) is lazy-loaded on first focus so the
// homepage doesn't pay for it up front.
(function () {
  const input = document.getElementById("search-input");
  const results = document.getElementById("search-results");
  if (!input || !results) return;

  let index = null;
  let loading = false;
  const pending = [];

  function ensureIndex(cb) {
    if (index) return cb();
    pending.push(cb);
    if (loading) return;
    loading = true;
    const script = document.createElement("script");
    script.src = "/search_index.en.js";
    script.onload = () => {
      index = elasticlunr.Index.load(window.searchIndex);
      while (pending.length) pending.shift()();
    };
    script.onerror = () => {
      loading = false;
      pending.length = 0;
      script.remove();
    };
    document.head.appendChild(script);
  }

  function excerpt(body) {
    return body.length > 160 ? body.slice(0, 160) + "…" : body;
  }

  function render(hits) {
    results.innerHTML = "";
    results.hidden = hits.length === 0;
    for (const hit of hits.slice(0, 8)) {
      const doc = index.documentStore.getDoc(hit.ref);
      const dt = document.createElement("dt");
      dt.className = "command hl-header";
      const link = document.createElement("a");
      link.className = "prog";
      // hit.ref is an absolute permalink built with the config base_url,
      // which zola serve does not rewrite; keep links same-origin.
      link.href = new URL(hit.ref).pathname;
      link.textContent = doc.title;
      dt.appendChild(link);
      const dd = document.createElement("dd");
      dd.className = "hl-body";
      dd.textContent = excerpt(doc.body);
      results.append(dt, dd);
    }
  }

  input.addEventListener("focus", () => ensureIndex(() => {}));
  input.addEventListener("input", () => {
    const query = input.value.trim();
    if (!query) {
      results.hidden = true;
      results.innerHTML = "";
      return;
    }
    ensureIndex(() => {
      render(
        index.search(query, {
          bool: "AND",
          expand: true,
          fields: { title: { boost: 2 }, body: { boost: 1 } },
        })
      );
    });
  });
})();
