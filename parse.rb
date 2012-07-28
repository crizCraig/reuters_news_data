require 'rexml/document'
require 'net/http'
require 'pp'
require 'rubygems'
require 'json'
require 'orderedhash'

def get_text(x)
  x ? x[0] : ''
end

articles = []

(1..21).each {|num|
  num_s = num.to_s.rjust(3, '0') # 001, 002..021

  f = File.open("xml/reut2-#{num_s}.sgm")
  c = f.read
  f.close

  reuters_tag = '<REUTERS '
  p = c.split(reuters_tag)

  attr_name_map = {
      'LEWISSPLIT' => 'lewis_split',
      'NEWID' => 'new_id',
      'TOPICS' => 'topics',
      'OLDID' => 'old_id',
      'CGISPLIT' => 'cgi_split'
  }
  el_names = %w(DATE TOPICS PEOPLE ORGS EXCHANGES COMPANIES TEXT)
  list_names = %w(TOPICS PEOPLE ORGS EXCHANGES COMPANIES)
  p.each_with_index { |xml, i|
    if i == 0
      # The first element is the DOCTYPE, ignore it.
      next
    end
    xml = reuters_tag + xml
    article_json = OrderedHash.new
    r = REXML::Document.new(xml)
    r.elements['REUTERS'].attributes.each { |k, v|
      article_json[attr_name_map[k]] = v
    }
    el_names.each do |n|
      x = r.elements['REUTERS/' + n]
      x = x[0]
      if list_names.include?(n)
        if x.respond_to?('children')
          article_json[n.downcase] = x.children
        else
          article_json[n.downcase] = []
        end
      elsif n == 'TEXT'
        article_json['title'] = get_text(r.elements['REUTERS/TEXT/TITLE'])
        article_json['dateline'] = get_text(r.elements['REUTERS/TEXT/DATELINE'])
        article_json['body'] = get_text(r.elements['REUTERS/TEXT/BODY'])
      else
        article_json[n.downcase] = x
      end
    end

    article_json.each { |k, v|
      article_json[k] = v.to_s.strip unless v.kind_of?(Array)
    }
    pp article_json
    articles.push(article_json)
    #out.to_json
    if i == 100
      break
    end
  }
}
out_file = File.open("reuters.json", 'w')
out_file.write(JSON.pretty_generate(articles))
out_file.close