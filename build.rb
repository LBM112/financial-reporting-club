#!/usr/bin/env ruby
# Financial Reporting Club — static site builder (no gems needed).
# Usage: ruby build.rb   → writes the finished site into ./site
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
require 'fileutils'
require 'date'
require 'cgi'
BUILD_ID = Time.now.to_i

ROOT = File.expand_path(__dir__)
OUT  = File.join(ROOT, 'site')

SITE = {
  name: 'Financial Reporting Club',
  tagline: 'Plain-English analysis of the deals that move markets.',
  email: 'dufinancialreportingclub@yahoo.com',
  socials: { 'Instagram' => 'https://www.instagram.com/dufinancialreportingclub/' }
}

# Sample ticker data (static placeholders, NOT live prices). Edit freely.
# [symbol, company, sector, logo file in assets/logos, price, change]
TICKER = [
  ['JPM',   'JPMorgan',          'Banking',            'jpm.svg',   '212.40',  1.25],
  ['GS',    'Goldman Sachs',     'Investment banking', 'gs.svg',    '498.15', -3.40],
  ['BLK',   'BlackRock',         'Asset management',   'blk.svg',   '842.70',  5.10],
  ['V',     'Visa',              'Payments',           'v.svg',     '276.55',  0.85],
  ['AAPL',  'Apple',             'Electronics',        'aapl.svg',  '189.30', -1.10],
  ['MSFT',  'Microsoft',         'Software',           'msft.svg',  '378.90',  2.65],
  ['NVDA',  'Nvidia',            'Semiconductors',     'nvda.svg',  '495.20', 12.30],
  ['GOOGL', 'Alphabet',          'Internet',           'googl.svg', '139.60',  1.05],
  ['VZ',    'Verizon',           'Telecoms',           'vz.svg',    '38.45',  -0.30],
  ['PFE',   'Pfizer',            'Pharmaceuticals',    'pfe.svg',   '28.75',  -0.15],
  ['UNH',   'UnitedHealth',      'Healthcare',         'unh.svg',   '528.40',  4.20],
  ['DAL',   'Delta',             'Airlines',           'dal.svg',   '41.20',   0.90],
  ['BA',    'Boeing',            'Aerospace',          'ba.svg',    '207.85', -2.75],
  ['TM',    'Toyota',            'Automotive',         'tm.svg',    '181.60',  1.40],
  ['FDX',   'FedEx',             'Logistics',          'fdx.svg',   '256.30',  3.15],
  ['UNP',   'Union Pacific',     'Railways',           'unp.svg',   '236.90', -1.60],
  ['XOM',   'ExxonMobil',        'Oil and gas',        'xom.svg',   '104.75',  0.55],
  ['NEE',   'NextEra',           'Utilities',          'nee.svg',   '58.20',  -0.45],
  ['CAT',   'Caterpillar',       'Machinery',          'cat.svg',   '291.10',  4.80],
  ['BHP',   'BHP',               'Mining',             'bhp.svg',   '57.85',  -0.70],
  ['LIN',   'Linde',             'Chemicals',          'lin.png',   '405.60',  2.30],
  ['WMT',   'Walmart',           'Retail',             'wmt.svg',   '163.40',  0.65],
  ['AMZN',  'Amazon',            'E-commerce',         'amzn.svg',  '147.25',  2.05],
  ['KO',    'Coca-Cola',         'Beverages',          'ko.svg',    '59.30',  -0.20],
  ['PG',    'Procter & Gamble',  'Consumer goods',     'pg.svg',    '152.80',  0.75],
  ['NKE',   'Nike',              'Sportswear',         'nke.svg',   '107.45', -1.35],
  ['MCD',   "McDonald's",        'Restaurants',        'mcd.svg',   '281.70',  1.95],
  ['DIS',   'Disney',            'Entertainment',      'dis.svg',   '91.15',   1.10],
  ['MAR',   'Marriott',          'Hospitality',        'mar.svg',   '219.50',  2.85],
  ['PLD',   'Prologis',          'Real estate',        'pld.svg',   '124.65', -0.90]
]

# ---------- tiny Markdown converter ----------
def inline(s)
  s = CGI.escapeHTML(s)
  s = s.gsub(/!\[([^\]]*)\]\(([^)]+)\)/, '<img src="\2" alt="\1">')
  s = s.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2">\1</a>')
  s = s.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
  s = s.gsub(/(?<![\w*])\*(?!\s)(.+?)\*(?!\w)/, '<em>\1</em>')
  s.gsub(/`([^`]+)`/, '<code>\1</code>')
end

def markdown(text)
  lines = text.split("\n")
  html = []
  i = 0
  while i < lines.size
    l = lines[i]
    if l.strip.empty?
      i += 1
    elsif l =~ /^(#{'#'}{1,4})\s+(.*)/
      n = $1.size
      html << "<h#{n + 1}>#{inline($2)}</h#{n + 1}>"
      i += 1
    elsif l =~ /^---+\s*$/
      html << '<hr>'; i += 1
    elsif l =~ /^>\s?/
      buf = []
      while i < lines.size && lines[i] =~ /^>\s?(.*)/
        buf << $1; i += 1
      end
      q = buf.join(' ')
      if q =~ /\A\*\*Bottom line:?\*\*:?\s*(.*)\z/m
        html << %(<aside class="callout" id="bottom-line"><p class="callout-label">Bottom line</p><p>#{inline($1)}</p></aside>)
      else
        html << "<blockquote>#{inline(q)}</blockquote>"
      end
    elsif l =~ /^\s*[-*]\s+/
      buf = []
      loop do
        j = i
        j += 1 while j < lines.size && lines[j].strip.empty?
        break unless j < lines.size && lines[j] =~ /^\s*[-*]\s+(.*)/
        buf << "<li>#{inline($1)}</li>"; i = j + 1
      end
      html << "<ul>#{buf.join}</ul>"
    elsif l =~ /^\s*\d+\.\s+/
      buf = []
      loop do
        j = i
        j += 1 while j < lines.size && lines[j].strip.empty?
        break unless j < lines.size && lines[j] =~ /^\s*\d+\.\s+(.*)/
        buf << "<li>#{inline($1)}</li>"; i = j + 1
      end
      html << "<ol>#{buf.join}</ol>"
    elsif l.start_with?('|')
      rows = []
      while i < lines.size && lines[i].start_with?('|')
        rows << lines[i]; i += 1
      end
      cells = ->(r) { r.strip.sub(/^\|/, '').sub(/\|$/, '').split('|').map(&:strip) }
      head = cells.(rows[0])
      body = rows[2..-1] || []
      t = '<div class="table-wrap"><table><thead><tr>' + head.map { |c| "<th>#{inline(c)}</th>" }.join + '</tr></thead><tbody>'
      body.each { |r| t << '<tr>' + cells.(r).map { |c| "<td>#{inline(c)}</td>" }.join + '</tr>' }
      html << t + '</tbody></table></div>'
    else
      buf = []
      while i < lines.size && !lines[i].strip.empty? && lines[i] !~ /^(#|>|\||\s*[-*]\s|\s*\d+\.\s|---)/
        buf << lines[i]; i += 1
      end
      html << "<p>#{inline(buf.join(' '))}</p>"
    end
  end
  html.join("\n")
end

# ---------- posts ----------
def load_post(path)
  raw = File.read(path)
  meta = {}
  body = raw
  if (m = raw.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m))
    m[1].each_line { |ln| k, v = ln.split(':', 2); meta[k.strip] = v.to_s.strip.gsub(/\A["']|["']\z/, '') if v }
    body = m[2]
  end
  slug = File.basename(path, '.md')
  words = body.split.size
  {
    slug: slug,
    title: meta['title'] || slug,
    author: meta['author'] || 'FRS Editorial',
    date: Date.parse(meta['date'] || File.mtime(path).to_s),
    summary: meta['summary'] || '',
    minutes: [(words / 200.0).ceil, 1].max,
    html: markdown(body)
  }
end

def fmt(d) d.strftime('%-d %B %Y') end

# ---------- page shell ----------
$latest = nil

def page(title, body, depth: 0, active: nil, hero: '')
  up = '../' * depth
  nav = [['Blogs', (active == 'home' && depth == 0 ? '#blogs' : "#{up}index.html#blogs"), 'home'], ['Join the Club', "#{up}join.html", 'join']]
        .map { |t, h, k| %(<a href="#{h}"#{k == active ? ' class="active" aria-current="page"' : ''}>#{t}</a>) }.join
  full_title = title ? "#{title} · #{SITE[:name]}" : SITE[:name]
  items = TICKER.map do |sym, company, sector, logo, price, chg|
    rising = chg >= 0
    num = format('%.2f', chg.abs)
    %(<span class="tick" title="#{CGI.escapeHTML(company)} · #{CGI.escapeHTML(sector)}"><span class="logo-chip"><img src="#{up}assets/logos/#{logo}" alt=""></span><span class="t-sym">#{sym}</span><span class="t-name">#{CGI.escapeHTML(company)}</span><span class="t-price">#{price}</span><span class="t-chg #{rising ? 'up' : 'down'}"><b>#{rising ? '&#9650;' : '&#9660;'}</b>#{num}</span></span>)
  end.join
  announce = %(<div class="ticker" role="region" aria-label="Sample market ticker (not live prices)"><div class="ticker-track" style="animation-duration:#{TICKER.size * 4}s"><div class="ticker-set">#{items}</div><div class="ticker-set" aria-hidden="true">#{items}</div></div></div>)
  <<~HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="Pragma" content="no-cache"><meta http-equiv="Expires" content="0">
      <title>#{CGI.escapeHTML(full_title)}</title>
      <meta name="description" content="#{CGI.escapeHTML(SITE[:tagline])}">
      <link rel="icon" href="#{up}assets/favicon.svg" type="image/svg+xml">
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
      <link rel="stylesheet" href="#{up}assets/style.css?v=#{BUILD_ID}">
    </head>
    <body>
    #{announce}
      <div class="frame">
        <header class="site-header">
          <a class="brand" href="#{up}index.html" aria-label="Financial Reporting Club, home">
            <img class="brand-logo" src="#{up}assets/logo.svg" alt="" width="44" height="44"><span class="wordmark"><span class="wm-top">Financial Reporting</span><span class="wm-bottom">Club</span></span>
          </a>
          <nav class="main-nav">#{nav}</nav>
        </header>
      </div>
      <main>
    #{hero}
    #{body}
      </main>
      <footer class="site-footer"><div class="wrap wide"><p><strong>#{CGI.escapeHTML(SITE[:name])}</strong></p><p class="fine">For education only, not investment advice.</p><p class="fine"><a href="mailto:#{SITE[:email]}">#{SITE[:email]}</a></p></div></footer>
      <script src="#{up}assets/site.js?v=#{BUILD_ID}"></script>
    </body>
    </html>
  HTML
end

# ---------- build ----------
FileUtils.rm_rf(OUT)
FileUtils.mkdir_p(File.join(OUT, 'posts'))
FileUtils.cp_r(File.join(ROOT, 'assets'), File.join(OUT, 'assets'))
Dir.glob(File.join(OUT, '**', '.DS_Store'), File::FNM_DOTMATCH).each { |f| File.delete(f) }

posts = Dir[File.join(ROOT, 'posts', '*.md')].map { |p| load_post(p) }.sort_by { |p| p[:date] }.reverse
$latest = posts.first

posts.each do |p|
  body = <<~HTML
    <figure class="banner banner-post"><img src="../assets/images/glass-towers.png" alt=""></figure>
    <article class="wrap post">
      <p class="back"><a href="../index.html">&larr; All articles</a></p>
      <h1>#{CGI.escapeHTML(p[:title])}</h1>
      <p class="byline">By <strong>#{CGI.escapeHTML(p[:author])}</strong> <span>&middot;</span> #{fmt(p[:date])} <span>&middot;</span> #{p[:minutes]} min read#{p[:html].include?('id="bottom-line"') ? ' <span>&middot;</span> <a class="skip" href="#bottom-line">Jump to the bottom line &darr;</a>' : ''}</p>
      <div class="prose">
    #{p[:html]}
      </div>
    </article>
  HTML
  File.write(File.join(OUT, 'posts', "#{p[:slug]}.html"), page(p[:title], body, depth: 1, active: 'home'))
end

featured, *rest = posts
# About panel shown on the homepage (placeholder text: edit freely)
ABOUT = {
  'What we are' => 'The Financial Reporting Club is an independently run student club that looks in depth at financial transactions, deals and trends, and at how they are priced and reported.',
  'What we write about' => 'We simplify complex financial transactions and make them readable for a wider audience, while judging how viable and reasonable each transaction was.',
  'The nature of the club' => 'We are an open club and anybody is welcome. If you are a reader, you are a member, and everyone is encouraged to get involved. We do not give investment advice, and our articles should not be used to make financial decisions.'
}

hero = <<~HTML
  <div><section class="hero hero-about">
    <p class="eyebrow">About the Club</p>
    <h1>Reports on the Complex Transactions in Corporate History</h1>
    <div class="about-cols">
      #{ABOUT.map { |h, t| %(<div class="about-item"><h2>#{CGI.escapeHTML(h)}</h2><p>#{CGI.escapeHTML(t)}</p></div>) }.join}
    </div>
    <a class="pill pill-white" href="join.html">Join the Club</a>
  </section></div>
HTML

home = +'<div class="wrap wide blogs-area"><h2 class="section-title reveal" id="blogs">Blogs by author</h2>'
posts.group_by { |p| p[:author] }.each do |author, list|
  home << %(<section class="author-row reveal"><div class="author-head"><h3>#{CGI.escapeHTML(author)}</h3><div class="scroll-btns"><button type="button" class="scroll-btn" data-dir="-1" aria-label="Scroll left">&larr;</button><button type="button" class="scroll-btn" data-dir="1" aria-label="Scroll right">&rarr;</button></div></div><div class="scroller" tabindex="0" role="region" aria-label="Articles by #{CGI.escapeHTML(author)}">)
  list.each do |p|
    home << <<~HTML
      <a class="card reveal" href="posts/#{p[:slug]}.html">
        <img src="assets/images/glass-towers.png" alt="" loading="lazy">
        <div class="card-body">
          <h4>#{CGI.escapeHTML(p[:title])}</h4>
          <p>#{CGI.escapeHTML(p[:summary])}</p>
          <span class="card-meta">#{fmt(p[:date])} &middot; #{p[:minutes]} min read</span>
        </div>
      </a>
    HTML
  end
  home << '</div></section>'
end
home << '</div>'
File.write(File.join(OUT, 'index.html'), page(nil, home, active: 'home', hero: hero))


socials = SITE[:socials].map { |n, u| %(<li><a href="#{u}">#{n}</a></li>) }.join
join_hero = <<~HTML
  <div><section class="hero hero-about hero-join">
    <p class="eyebrow">Join the Club</p>
    <h1>Join the Club</h1>
    <p class="join-lede">Joining officially is as simple as following the Instagram page. Do so for information on new releases or opportunities within the club.</p>
    <div class="about-grid">
      <div class="about-item"><h2>Follow us</h2><p>#{SITE[:socials].map { |n, u| %(<a href="#{u}">#{n}</a>) }.join(', ')}</p></div>
      <div class="about-item"><h2>Questions or ideas</h2><p>For questions or ideas, email us at <a href="mailto:#{SITE[:email]}">#{SITE[:email]}</a>.</p></div>
    </div>
    <p class="hero-credit">Ernst &amp; Young and Westpac offices, Auckland</p>
  </section></div>
HTML
File.write(File.join(OUT, 'join.html'), page('Join the Club', '', active: 'join', hero: join_hero))

puts "Built #{posts.size} article(s) into #{OUT}"
