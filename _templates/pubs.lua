-- The {{< pubs >}} shortcode: assembles publication lists from ../_publications.yml.
--
-- _quarto.yml merges that file into every document's metadata, so this filter only
-- has to read `meta.publications`, pick the entries a page asked for, and typeset
-- them for the format being rendered:
--
--   html    a .pub row — year | title / authors — matching the classes in styles.scss
--   typst   a reference-list bullet: Authors (Year). Title. Venue.
--
-- Keeping both in one place is the point: the web page and the CV PDFs stay in step
-- without the same paper being written out twice.
--
-- Options, all optional:
--
--   type=article      one type, or a comma-separated set
--   selected=true     only entries flagged `selected: true`
--   titles=short      prefer `title-short:` where an entry defines one
--   limit=4           keep at most N entries, after sorting
--   show=summary      how much of an entry's prose to print (default "summary"):
--                       none      citation only
--                       summary   citation + the one-line `summary:`
--                       full      citation + `summary:` + the `description:` paragraph
--
-- Entries come out newest first; ties keep their order in _publications.yml.

local stringify = pandoc.utils.stringify

-- Metadata scalars arrive as Inlines, because Pandoc parses YAML scalar values as
-- Markdown. That is what lets a title be written `CO~2~` once and come out as
-- <sub>2</sub> in HTML and CO#sub[2] in Typst. Anything else is coerced here.
local function inls(value)
  if value == nil then return nil end
  if type(value) == 'string' then
    return pandoc.Inlines(pandoc.read(value, 'markdown').blocks[1].content)
  end
  if type(value) == 'boolean' or type(value) == 'number' then
    return pandoc.Inlines{ pandoc.Str(tostring(value)) }
  end
  return pandoc.Inlines(value)
end

local COMMA  = pandoc.Inlines{ pandoc.Str(','), pandoc.Space() }
local MIDDOT = pandoc.Inlines{ pandoc.Space(), pandoc.Str('·'), pandoc.Space() }

local function join(parts, separator)
  local out = pandoc.Inlines{}
  for i, part in ipairs(parts) do
    if i > 1 then out:extend(separator) end
    out:extend(part)
  end
  return out
end

-- `mark` sets the site owner's own name off from co-authors: a .me span on the web,
-- plain emphasis in the CVs.
local function author_line(entry, me, mark)
  local parts = {}
  for _, author in ipairs(entry.authors or {}) do
    local one = inls(author)
    if me ~= '' and stringify(one) == me then one = mark(one) end
    parts[#parts + 1] = one
  end
  return join(parts, COMMA)
end

-- Everything trailing the authors on the citation line: an italicised journal with
-- its volume and pages, or a plain venue. The `summary:` is deliberately not here —
-- on the web it gets its own line, and only the CV runs it into the citation.
local function venue_parts(entry)
  local parts = {}
  if entry.journal then
    local one = pandoc.Inlines{ pandoc.Emph(inls(entry.journal)) }
    if entry.detail then
      one:insert(pandoc.Space())
      one:extend(inls(entry.detail))
    end
    parts[#parts + 1] = one
  end
  if entry.where then parts[#parts + 1] = inls(entry.where) end
  return parts
end

local function summary_of(entry, show)
  if show == 'none' or entry.summary == nil then return nil end
  return inls(entry.summary)
end

-- The CV punctuates each part as a sentence, but titles ending in "?" and
-- summaries written as full sentences already carry their own terminator.
local function ends_sentence(inlines)
  local text = stringify(inlines)
  return text:sub(-1):match('[%.%?!]') ~= nil
end

local function long_description(entry, show)
  if show ~= 'full' or entry.description == nil then return nil end
  return inls(entry.description)
end

local function title_of(entry, short)
  if short and entry['title-short'] then return inls(entry['title-short']) end
  return inls(entry.title)
end

-- Where a row points, most specific first: a page on this site, then an explicit
-- URL, then the DOI. nil when the entry has nowhere to go — such rows must not be
-- links at all, since a placeholder href only jerks the reader to the top of the page.
local function href_of(entry)
  if entry.page then
    -- Site-root-relative, written as authored (`notes/foo.qmd`).
    return (stringify(entry.page):gsub('%.qmd$', '.html'))
  end
  if entry.url then return stringify(entry.url) end
  if entry.doi then return 'https://doi.org/' .. stringify(entry.doi) end
  return nil
end

local function html_of(blocks)
  return (pandoc.write(pandoc.Pandoc(blocks), 'html'):gsub('%s+$', ''))
end

-- The grid cells of one row: the year, then a stack of title / citation / summary.
local function row_content(entry, me, short, show, title)
  local authors = author_line(entry, me, function(one)
    return pandoc.Inlines{ pandoc.Span(one, pandoc.Attr('', { 'me' })) }
  end)

  local citation = { authors }
  for _, part in ipairs(venue_parts(entry)) do citation[#citation + 1] = part end

  -- Spaces between the cells, as in cv.lua: never seen on the page, where each one
  -- is a block or a grid cell, but they keep "2025The effects of…" apart in the
  -- plain-text copies of the page (the llms.txt Markdown, the search index).
  local body = pandoc.List{
    pandoc.Span(title, pandoc.Attr('', { 'ttl' })),
    pandoc.Space(),
    pandoc.Span(join(citation, MIDDOT), pandoc.Attr('', { 'aut' })),
  }

  -- The short description reads as content, not as more citation metadata, so it
  -- gets its own line under the authors rather than another ` · ` fragment.
  local summary = summary_of(entry, show)
  if summary then
    body:insert(pandoc.Space())
    body:insert(pandoc.Span(summary, pandoc.Attr('', { 'sum' })))
  end

  return pandoc.List{
    pandoc.Span(inls(entry.year), pandoc.Attr('', { 'yr' })),
    pandoc.Space(),
    pandoc.Span(body),
  }
end

local function web_row(entry, me, short, show)
  local url         = href_of(entry)
  local description = long_description(entry, show)
  local title       = title_of(entry, short)

  if description == nil then
    local content = row_content(entry, me, short, show, title)
    if url then
      return pandoc.Plain{ pandoc.Link(content, url, '', pandoc.Attr('', { 'pub' })) }
    end
    -- Nowhere to go: render the row as a plain block rather than a link that
    -- would only bounce the reader to the top of the page.
    return pandoc.Div(pandoc.Blocks{ pandoc.Plain(content) }, pandoc.Attr('', { 'pub' }))
  end

  -- With a long description the row becomes a disclosure — clicking it expands the
  -- prose instead of navigating — so any outbound link moves onto the title, and
  -- the whole thing is emitted as raw <details>, the same pattern cv.qmd uses for
  -- its timeline. Block content cannot nest inside an <a> anyway.
  if url then title = pandoc.Inlines{ pandoc.Link(title, url, '') } end

  local content = row_content(entry, me, short, show, title)
  -- Empty: styles.scss draws the + with `::before`, as it does for the CV's rows.
  content:insert(pandoc.Span({}, pandoc.Attr('', { 'plus' })))

  return pandoc.RawBlock('html', table.concat({
    '<details class="pub-entry">',
    '<summary class="pub">', html_of{ pandoc.Plain(content) }, '</summary>',
    '<div class="pub-more">', html_of{ pandoc.Para(description) }, '</div>',
    '</details>',
  }, '\n'))
end

local function cv_item(entry, me, short, show)
  local out = author_line(entry, me, function(one)
    return pandoc.Inlines{ pandoc.Emph(one) }
  end)
  out:extend{ pandoc.Space(), pandoc.Str('(') }
  out:extend(inls(entry.year))
  out:extend{ pandoc.Str(').'), pandoc.Space() }

  local title = title_of(entry, short)
  out:extend(title)
  if not ends_sentence(title) then out:insert(pandoc.Str('.')) end

  -- The CV has no room for a separate line, so the summary runs into the citation.
  local parts = venue_parts(entry)
  local summary = summary_of(entry, show)
  if summary then parts[#parts + 1] = summary end

  for _, part in ipairs(parts) do
    out:insert(pandoc.Space())
    out:extend(part)
    if not ends_sentence(part) then out:insert(pandoc.Str('.')) end
  end

  local blocks = pandoc.Blocks{ pandoc.Plain(out) }
  local description = long_description(entry, show)
  if description then
    blocks:insert(pandoc.Para(description))
  end
  return blocks
end

local function option(kwargs, name)
  if kwargs[name] == nil then return '' end
  return stringify(kwargs[name])
end

-- "article", or "working-paper,report" -> a lookup table; nil means "any type".
local function type_set(spec)
  if spec == '' then return nil end
  local set = {}
  for one in spec:gmatch('[^,%s]+') do set[one] = true end
  return set
end

local function select_entries(meta, kwargs)
  local types    = type_set(option(kwargs, 'type'))
  local selected = option(kwargs, 'selected') == 'true'
  local limit    = tonumber(option(kwargs, 'limit'))

  local kept = {}
  for i, entry in ipairs(meta.publications) do
    local wanted = true
    if types and not types[stringify(entry.type or '')] then wanted = false end
    if selected and entry.selected ~= true then wanted = false end
    if wanted then kept[#kept + 1] = { entry = entry, order = i } end
  end

  -- Newest first. table.sort is not stable, hence the explicit fall back to file order.
  table.sort(kept, function(a, b)
    local ya = tonumber(stringify(a.entry.year or '')) or 0
    local yb = tonumber(stringify(b.entry.year or '')) or 0
    if ya ~= yb then return ya > yb end
    return a.order < b.order
  end)

  local entries = {}
  for i, row in ipairs(kept) do
    if limit and i > limit then break end
    entries[#entries + 1] = row.entry
  end
  return entries
end

return {
  ['pubs'] = function(args, kwargs, meta)
    if meta.publications == nil then
      quarto.log.error('pubs: no `publications` in metadata — is _publications.yml ' ..
                       'still listed under `metadata-files:` in _quarto.yml?')
      return pandoc.Blocks{}
    end

    local me      = meta['author-me'] and stringify(meta['author-me']) or ''
    local short   = option(kwargs, 'titles') == 'short'
    local show    = option(kwargs, 'show')
    local entries = select_entries(meta, kwargs)

    if show == '' then show = 'summary' end
    if show ~= 'none' and show ~= 'summary' and show ~= 'full' then
      quarto.log.error('pubs: show="' .. show .. '" is not one of none, summary, full.')
      show = 'summary'
    end

    if quarto.doc.is_format('html') then
      local blocks = pandoc.Blocks{}
      for _, entry in ipairs(entries) do
        blocks:insert(web_row(entry, me, short, show))
      end
      return blocks
    end

    local items = pandoc.List{}
    for _, entry in ipairs(entries) do
      items:insert(cv_item(entry, me, short, show))
    end
    return pandoc.Blocks{ pandoc.BulletList(items) }
  end,
}
