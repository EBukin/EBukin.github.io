-- The {{< cv >}} shortcode: assembles CV sections from ../_cv.yml.
--
-- The sibling of pubs.lua, and deliberately written to read like it: _quarto.yml
-- merges _cv.yml into every document's metadata, so this filter only has to read
-- `meta.cv`, pick the entries a page asked for, and typeset them for the format:
--
--   html    a <details> timeline row — period / title / place / one sentence, with
--           the long text behind the +, matching the .timeline classes in styles.scss
--   typst   a #cv-entry() call, defined in cv/_typst-style.typ: role and employer
--           left, period hard right, prose underneath
--
-- The four small helpers below (inls, join, option, type_set) are copied from
-- pubs.lua rather than shared. Quarto renders cv/cv-full.qmd from a different working
-- directory than the root pages, and require/dofile resolution is not worth the risk
-- across Quarto 1.9.x (CI) and 1.10.x (local) for four pure functions. If one of them
-- is fixed here, fix it there too.
--
-- Options:
--
--   type=experience   one type, or a comma-separated set; omitted means every type
--   in=short          keep only entries whose `in:` list names this variant
--   titles=short      prefer `title-short:` / `place-short:` where an entry defines
--                     them — the tight headings the two-page CV needs
--   show=summary      how much of an entry's prose to print (default "summary"):
--                       none      heading only
--                       summary   heading + `summary:`
--                       full      heading + `summary:` and then `description:`, which
--                                 continues it rather than repeating it, and references
--   limit=4           keep at most N entries
--
-- Entries come out in file order. Unlike publications nothing is sorted: `period:`
-- is a display string, and _cv.yml is already in the order the CV should read.
--
-- This file also carries two shortcodes that take no entries at all:
--
--   {{< cv-header >}}   the identity block at the top of a PDF — name, headline,
--                       appointments, contact line — every field read from `cv-me:`
--                       in _cv.yml. It is why the two .qmd files state no fact about
--                       the person: there is nowhere in them left to state one.
--                       Nothing on the web; cv.qmd has the site header and its own
--                       hero above it already
--   {{< cv-pdf >}}      the download link for one of the typeset CVs. It exists as a
--                       shortcode only so the saved file can be named after the
--                       reader's benefit rather than the repo's layout: cv-short.pdf
--                       on the server arrives as Bukin-2026-09-08-short.pdf in their
--                       downloads folder

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

-- `description:` is the one field that is more than a sentence — it carries bullet
-- lists — so it needs the blocks, not just the inlines of the first paragraph that
-- inls() would return. Pandoc's YAML reader hands back Blocks when a value parses
-- to more than one block and Inlines when it is a lone paragraph; both arrive here.
local BLOCK_TAGS = {
  BlockQuote = true, BulletList = true, CodeBlock = true, DefinitionList = true,
  Div = true, Figure = true, Header = true, HorizontalRule = true, LineBlock = true,
  OrderedList = true, Para = true, Plain = true, RawBlock = true, Table = true,
}

local function blks(value)
  if value == nil then return nil end
  if type(value) == 'string' then
    return pandoc.read(value, 'markdown').blocks
  end
  local first = value[1]
  if first ~= nil and first.t ~= nil and BLOCK_TAGS[first.t] then
    return pandoc.Blocks(value)
  end
  return pandoc.Blocks{ pandoc.Para(pandoc.Inlines(value)) }
end

local MIDDOT = pandoc.Inlines{ pandoc.Space(), pandoc.Str('·'), pandoc.Space() }

local function join(parts, separator)
  local out = pandoc.Inlines{}
  for i, part in ipairs(parts) do
    if i > 1 then out:extend(separator) end
    out:extend(part)
  end
  return out
end

local function option(kwargs, name)
  if kwargs[name] == nil then return '' end
  return stringify(kwargs[name])
end

-- Plain text that is not Markdown and must not be read as it — a name split off
-- `name:`, a URL. Pandoc's writers escape a Str for the format they are writing.
local function txt(value)
  return pandoc.Inlines{ pandoc.Str(value) }
end

-- A call to one of the functions in cv/_typst-style.typ, assembled by interleaving
-- raw Typst fragments with Pandoc inlines. Passing the fields through as inlines
-- rather than as strings is the point: Pandoc's Typst writer still gets to write
-- them, so the Markdown in a field — emphasis, a link, the `CO~2~` subscript that
-- _cv.yml is allowed to contain — comes out as Typst markup and not as literal text.
local function typst_call(parts)
  local out = pandoc.Inlines{}
  for _, part in ipairs(parts) do
    if type(part) == 'string' then
      out:insert(pandoc.RawInline('typst', part))
    else
      out:extend(part)
    end
  end
  return out
end

-- `name: [content], ` for each field that has a value, skipping the rest so the
-- Typst function's own defaults decide what an absent field means.
local function typst_fields(fields)
  local parts = {}
  for _, field in ipairs(fields) do
    if field[2] ~= nil then
      parts[#parts + 1] = field[1] .. ': ['
      parts[#parts + 1] = field[2]
      parts[#parts + 1] = '], '
    end
  end
  return parts
end

-- "experience", or "skills,languages" -> a lookup table; nil means "any type".
local function type_set(spec)
  if spec == '' then return nil end
  local set = {}
  for one in spec:gmatch('[^,%s]+') do set[one] = true end
  return set
end

-- The variants an entry belongs to. nil `in:` means every variant, which is also
-- what the web page shows before any button is pressed.
local ALL_VARIANTS = { 'short', 'full' }

local function variants_of(entry)
  if entry['in'] == nil then return ALL_VARIANTS end
  local list = {}
  for _, one in ipairs(entry['in']) do list[#list + 1] = stringify(one) end
  return list
end

local function has_variant(entry, want)
  for _, one in ipairs(variants_of(entry)) do
    if one == want then return true end
  end
  return false
end

-- `title` / `title-short` and `place` / `place-short` — one rule for both pairs, and
-- the same idea as `title-short:` in _publications.yml: the short CV wants a heading
-- that fits one line, everywhere else wants the full name.
local function pick(entry, name, short)
  if short and entry[name .. '-short'] then return inls(entry[name .. '-short']) end
  if entry[name] == nil then return nil end
  return inls(entry[name])
end

local function summary_of(entry, show)
  if show == 'none' or entry.summary == nil then return nil end
  return inls(entry.summary)
end

local function description_of(entry, show)
  if show ~= 'full' or entry.description == nil then return nil end
  return blks(entry.description)
end

-- A `type: profile` entry, and the one shape that comes out identically in both
-- formats — a paragraph is a paragraph. `show=` does not apply to it: a profile is
-- all it is.
local function prose_of(entry)
  return blks(entry.text) or pandoc.Blocks{}
end

-- Quarto has renamed its logging functions between versions; this site renders on
-- 1.9.x in CI and 1.10.x locally, so take whichever of them exists.
local function log_warn(message)
  local log  = quarto and quarto.log
  local sink = log and (log.warning or log.warn or log.output)
  if sink then sink(message) else print(message) end
end

-- Line breaks in a YAML block scalar survive as SoftBreaks, so compare on collapsed
-- whitespace rather than on the literal strings.
local function flatten(text)
  return (text:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1'))
end

-- The rule _cv.yml states — a description carries what its summary does not, because
-- everything that prints the one prints the other above it: the web row keeps its
-- `.sum` visible when it opens, and show=full sets the summary as the entry's first
-- paragraph. Nothing can enforce it, so say so at render time instead of shipping an
-- entry that says the same thing twice.
local function warn_on_repeat(entry)
  if entry.summary == nil or entry.description == nil then return end
  local summary = flatten(stringify(inls(entry.summary)))
  local body    = flatten(stringify(blks(entry.description)))
  if summary ~= '' and body:sub(1, #summary) == summary then
    log_warn('cv: `description:` repeats `summary:` for "' ..
             stringify(inls(entry.title or '?')) .. '" — the two are printed one after ' ..
             'the other, so the entry would say the same thing twice.')
  end
end

-- ---- html -------------------------------------------------------------------

-- A timeline row. Only the <details>/<summary> tags are raw, because neither is a
-- Pandoc element; the summary line stays a Plain of Spans and the body a Div, so the
-- Markdown in them keeps flowing through the rest of Quarto's filter chain. This is
-- the same block sequence Pandoc's reader produced from the hand-written <details>
-- blocks in cv.qmd that this shortcode replaces.
--
-- The three spans sit inside one unclassed wrapper because `.timeline summary` is a
-- `grid-template-columns: 1fr 20px` grid: all the text belongs to the first cell and
-- the + to the second.
local function web_entry(entry)
  local head = pandoc.List{}
  if entry.period then
    head:insert(pandoc.Span(inls(entry.period), pandoc.Attr('', { 'when' })))
  end
  if entry.title then
    head:insert(pandoc.Span(inls(entry.title), pandoc.Attr('', { 'role' })))
  end
  if entry.place then
    head:insert(pandoc.Span(inls(entry.place), pandoc.Attr('', { 'org' })))
  end

  -- The row's short form. `.sum` is the class pubs.lua already uses for the same idea;
  -- styles.scss gives it a .timeline variant. It stays visible when the entry opens,
  -- because _cv.yml requires `description:` to carry what it does not say: the body
  -- below continues the line rather than replacing it.
  local summary = summary_of(entry, 'summary')
  if summary then
    head:insert(pandoc.Span(summary, pandoc.Attr('', { 'sum' })))
  end

  -- The web page always carries the whole story; the switcher decides what shows.
  local body    = description_of(entry, 'full')
  local variant = table.concat(variants_of(entry), ' ')

  -- With the summary no longer repeated below it, an entry that has no `description:`
  -- has nothing to disclose, so it is a plain row and carries no +: a control that
  -- opened onto an empty box would be a control that does nothing. It keeps the
  -- .cv-entry class and the data-in attribute, which is all the switcher reads.
  if body == nil or #body == 0 then
    return pandoc.Blocks{
      pandoc.Div(pandoc.Blocks{ pandoc.Plain(pandoc.Span(head)) },
                 pandoc.Attr('', { 'cv-entry' }, { ['data-in'] = variant })),
    }
  end

  return pandoc.Blocks{
    pandoc.RawBlock('html', '<details class="cv-entry" data-in="' .. variant .. '">'),
    pandoc.RawBlock('html', '<summary>'),
    pandoc.Plain{
      pandoc.Span(head),
      pandoc.Span({ pandoc.Str('+') }, pandoc.Attr('', { 'plus' })),
    },
    pandoc.RawBlock('html', '</summary>'),
    pandoc.Div(body, pandoc.Attr('', { 'body' })),
    pandoc.RawBlock('html', '</details>'),
  }
end

-- Skills, languages and scholarships have no dates and nothing to disclose, so they
-- reuse the chip row the home and teaching pages already use. The optional `label:`
-- rides inside the same wrapper as the chips, so when the switcher hides the row the
-- name goes with it — three unlabelled chip rows under one heading are unreadable.
local function web_list(entry)
  local chips = pandoc.List{}
  for i, item in ipairs(entry.items or {}) do
    if i > 1 then chips:insert(pandoc.Space()) end
    chips:insert(pandoc.Span(inls(item), pandoc.Attr('', { 'chip-out' })))
  end

  local inner = pandoc.Blocks{}
  if entry.label then
    inner:insert(pandoc.Plain{
      pandoc.Span(inls(entry.label), pandoc.Attr('', { 'eyebrow' })),
    })
  end
  inner:insert(pandoc.Div(pandoc.Blocks{ pandoc.Plain(chips) },
                          pandoc.Attr('', { 'chips' })))

  return pandoc.Div(inner, pandoc.Attr('', { 'cv-list', 'cv-entry' },
                    { ['data-in'] = table.concat(variants_of(entry), ' ') }))
end

-- ---- typst ------------------------------------------------------------------

-- Everything that is prose rather than a heading goes inside `#cv-detail[…]`, which
-- indents it into a column of its own. Emitted as two raw blocks around the real
-- Pandoc blocks rather than as one string, because the body may be paragraphs and
-- bullet lists and it is still Pandoc's job to write those.
local function cv_detail(blocks)
  if blocks == nil or #blocks == 0 then return pandoc.Blocks{} end
  local out = pandoc.Blocks{ pandoc.RawBlock('typst', '#cv-detail[') }
  out:extend(blocks)
  out:insert(pandoc.RawBlock('typst', ']'))
  return out
end

-- A #cv-entry() call rather than a heading, because the modern-cv layout needs the
-- three fields separately: a single run of "{title} — {place} · {period}" is what
-- used to wrap a long role onto two lines and push the dates around with it.
local function cv_entry(entry, show, short)
  local call = { '#cv-entry(' }
  for _, part in ipairs(typst_fields{
    { 'title',  pick(entry, 'title', short) },
    { 'place',  pick(entry, 'place', short) },
    { 'period', entry.period and inls(entry.period) or nil },
  }) do
    call[#call + 1] = part
  end
  call[#call + 1] = ')'

  -- The summary first and the description after it, never one instead of the other:
  -- _cv.yml requires the description to continue the summary rather than restate it,
  -- so at show=full the two are the opening paragraph and the rest of one passage.
  -- summary_of() is nil at show=none and description_of() at anything below full, so
  -- the three depths fall out of the two calls.
  local body = pandoc.Blocks{}
  local summary = summary_of(entry, show)
  if summary then body:insert(pandoc.Para(summary)) end
  local detail = description_of(entry, show)
  if detail then body:extend(detail) end

  -- The references note belongs to the entry, so it is indented with the rest of it
  -- rather than left hanging back out at the margin.
  if show == 'full' and entry.references then
    local line = pandoc.Inlines{ pandoc.Emph{ pandoc.Str('References:') }, pandoc.Space() }
    line:extend(inls(entry.references))
    body:insert(pandoc.Plain(typst_call{ '#cv-note[', line, ']' }))
  end

  local blocks = pandoc.Blocks{ pandoc.Plain(typst_call(call)) }
  blocks:extend(cv_detail(body))
  return blocks
end

local function cv_list(entry)
  local parts = {}
  for _, item in ipairs(entry.items or {}) do parts[#parts + 1] = inls(item) end
  return cv_detail(pandoc.Blocks{ pandoc.Para(join(parts, MIDDOT)) })
end

-- ---- selection ---------------------------------------------------------------

local function select_entries(meta, kwargs)
  local types   = type_set(option(kwargs, 'type'))
  local variant = option(kwargs, 'in')
  local limit   = tonumber(option(kwargs, 'limit'))

  local entries = {}
  for _, entry in ipairs(meta.cv) do
    local wanted = true
    if types and not types[stringify(entry.type or '')] then wanted = false end
    if variant ~= '' and not has_variant(entry, variant) then wanted = false end
    if wanted then
      entries[#entries + 1] = entry
      if limit and #entries >= limit then break end
    end
  end
  return entries
end

-- The name the browser saves the file under: surname, the date the site was built,
-- and which CV it is. The surname comes from `author-me` in _publications.yml ("Bukin,
-- E." -> "Bukin") so there is no second place to update it.
local function download_name(meta, variant)
  local who = meta['author-me'] and stringify(meta['author-me']) or 'CV'
  who = who:match('^[^,]+') or who
  who = who:gsub('%s+$', ''):gsub('%s', '-')
  return who .. '-' .. os.date('%Y-%m-%d') .. '-' .. variant .. '.pdf'
end

return {
  -- {{< cv-header >}} — the identity block at the top of a typeset CV, every field
  -- read from `cv-me:` in _cv.yml. cv/_typst-style.typ lays it out; this only has to
  -- hand #cv-header() the pieces.
  --
  -- Nothing on the web: cv.qmd sits under the site navbar and its own hero, and a
  -- second name and contact line beneath those would only be noise.
  ['cv-header'] = function(args, kwargs, meta)
    if quarto.doc.is_format('html') then return pandoc.Blocks{} end

    local me = meta['cv-me']
    if me == nil then
      quarto.log.error('cv-header: no `cv-me` in metadata — is _cv.yml still listed ' ..
                       'under `metadata-files:` in _quarto.yml?')
      return pandoc.Blocks{}
    end

    -- Awesome-CV, and modern-cv after it, sets the surname against a lighter given
    -- name; splitting on the last space is the whole rule. A one-word name is all
    -- surname and comes out at the heavier weight, which is the right answer anyway.
    local name = me.name and stringify(inls(me.name)) or ''
    local first, last = name:match('^(.-)%s+(%S+)$')
    if last == nil then first, last = nil, name end

    local call = { '#cv-header(' }
    for _, part in ipairs(typst_fields{
      { 'first',    first and txt(first) or nil },
      { 'last',     txt(last) },
      { 'headline', me.headline and inls(me.headline) or nil },
      { 'footline', me.updated and
                    txt(name .. ' · updated ' .. stringify(inls(me.updated))) or nil },
    }) do
      call[#call + 1] = part
    end

    -- Typst needs the trailing comma on a one-element array, so every element gets
    -- one and the two lists below read the same whatever their length.
    call[#call + 1] = 'positions: ('
    for _, one in ipairs(me.positions or {}) do
      call[#call + 1] = '['
      call[#call + 1] = inls(one)
      call[#call + 1] = '], '
    end
    call[#call + 1] = '), links: ('
    for _, one in ipairs(me.links or {}) do
      if one.url then
        call[#call + 1] = '['
        call[#call + 1] = pandoc.Inlines{
          pandoc.Link(inls(one.text or one.url), stringify(one.url)),
        }
        call[#call + 1] = '], '
      end
    end
    call[#call + 1] = '))'

    -- Two set rules of our own before the header itself, both here rather than in
    -- cv/_typst-style.typ with the rest of the design, and for the same reason:
    -- Quarto's Typst template runs *after* the header include, and both of these are
    -- things it has an opinion about. It sets `par(justify: true, …)`, which
    -- `cv-body` has to overrule; and it sets `document(title: title)`, which with no
    -- `title:` in the .qmd would clear the PDF's own title. A document set rule is
    -- legal only before any content, which is why these lead the body.
    --
    -- The PDF title is what a reader's viewer shows in its window and what the
    -- downloaded file reports about itself, and it comes from `cv-me.name:` so the
    -- name is still written down in exactly one place.
    local quoted = name:gsub('"', '')
    return pandoc.Blocks{
      pandoc.RawBlock('typst', '#set document(title: "' .. quoted ..
                               ' — curriculum vitae", author: "' .. quoted .. '")'),
      pandoc.RawBlock('typst', '#show: cv-body'),
      pandoc.Plain(typst_call(call)),
    }
  end,

  -- {{< cv-pdf variant=short label=PDF >}} — a download link, not a viewer link: the
  -- `download` attribute is what stops the browser opening the PDF in a tab instead.
  ['cv-pdf'] = function(args, kwargs, meta)
    local variant = option(kwargs, 'variant')
    if variant == '' then
      log_warn('cv-pdf: needs variant=short or variant=full.')
      return pandoc.Blocks{}
    end
    local label = option(kwargs, 'label')
    if label == '' then label = 'PDF' end

    -- Both links read "PDF", and which is which is carried by the button each one
    -- sits under. That works by eye and not at all by ear, hence the aria-label.
    return pandoc.RawInline('html', table.concat({
      '<a class="btn-pdf" href="cv/cv-', variant, '.pdf" download="',
      download_name(meta, variant), '" aria-label="Download the ', variant,
      ' CV as PDF">', label, '</a>',
    }))
  end,

  ['cv'] = function(args, kwargs, meta)
    if meta.cv == nil then
      quarto.log.error('cv: no `cv` in metadata — is _cv.yml still listed under ' ..
                       '`metadata-files:` in _quarto.yml?')
      return pandoc.Blocks{}
    end

    local short   = option(kwargs, 'titles') == 'short'
    local show    = option(kwargs, 'show')
    local entries = select_entries(meta, kwargs)

    -- A mistyped type= would otherwise render an empty section in silence.
    if #entries == 0 then
      log_warn('cv: type="' .. option(kwargs, 'type') .. '" in="' ..
               option(kwargs, 'in') .. '" matched no entries in _cv.yml.')
    end

    if show == '' then show = 'summary' end
    if show ~= 'none' and show ~= 'summary' and show ~= 'full' then
      quarto.log.error('cv: show="' .. show .. '" is not one of none, summary, full.')
      show = 'summary'
    end

    -- The web page carries every entry at full depth and lets the Short / Full
    -- buttons filter and collapse it, so `show=` is a PDF concern only.
    if quarto.doc.is_format('html') then
      local blocks = pandoc.Blocks{}
      for _, entry in ipairs(entries) do
        if entry.items then
          blocks:insert(web_list(entry))
        elseif entry.text then
          blocks:insert(pandoc.Div(prose_of(entry), pandoc.Attr('', { 'cv-entry' },
                        { ['data-in'] = table.concat(variants_of(entry), ' ') })))
        else
          warn_on_repeat(entry)
          blocks:extend(web_entry(entry))
        end
      end
      return blocks
    end

    local blocks = pandoc.Blocks{}
    for _, entry in ipairs(entries) do
      if entry.items then
        blocks:extend(cv_list(entry))
      elseif entry.text then
        blocks:extend(cv_detail(prose_of(entry)))
      else
        blocks:extend(cv_entry(entry, show, short))
      end
    end
    return blocks
  end,
}
