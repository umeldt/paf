# encoding: utf-8

require 'json'

class Distribution < Sequel::Model
  many_to_one :entry, :class => 'Entry'
  many_to_one :member, :class => 'Member'

  def frequency
    case distribution
    when /f/i then "Frequent"
    when /s/i then "Scattered"
    when /r/i then "Rare"
    when /x/i then "Present (Frequency unknown)"
    when '?' then "Presence uncertain"
    when /b/i then "Present only in the Borderline Arctic"
    when '*' then "Persistent (Adventive)"
    when '**' then "Casual (Adventive)"
    end
  end

  def where
    case area
    when 'Ic' then "Northern Iceland"
    when 'FN' then "Northern Fennoscandia"
    when 'KP' then "Kanin - Pechora"
    when 'SF' then "Svalbard - Franz Joseph Land"
    when 'UN' then "Polar Ural - Novaya Zemlya"
    when 'YG' then "Yamal - Gydan"
    when 'Tm' then "Taimyr - Severnaya Zemlya"
    when 'AO' then "Anabar - Onenyo"
    when 'Kh' then "Kharaulakh"
    when 'YK' then "Yana - Kolyma"
    when 'CW' then "West Chukotka"
    when 'WI' then "Wrangel Island"
    when 'CS' then "South Chukotka"
    when 'CE' then "East Chukotka"
    when 'AW' then "Western Alaska"
    when 'AN' then "Northern Alaska - Yukon"
    when 'CC' then "Central Canada"
    when 'HL' then "Hudson Bay - Labrador"
    when 'EP' then "Ellesmere Island"
    when 'GW' then "Western Greenland"
    when 'GE' then "Eastern Greenland"
      
    when 'A' then "Polar desert"
    when 'B' then "Northern arctic Tundra"
    when 'C' then "Mid Arctic Tundra"
    when 'D' then "Southern Arcti Tundra"
    when 'E' then "Shrub Tundra"
    when 'N' then "Bordering boreal or alpine areas"
    else area
    end
  end

  def summary
    "<b>#{where}:</b> <i>#{frequency}</i>"
  end
end

class Image < Sequel::Model
  many_to_one :entry, :class => 'Entry'
end

class Synonym < Sequel::Model
  many_to_one :entry, :class => 'Entry'
end

class Reference < Sequel::Model
  many_to_one :entry, :class => 'Entry'
end

class Member < Sequel::Model
  many_to_one :entry, :class => 'Entry'
  one_to_many :distribution, :class => Distribution

  def summary
    summary = ["<i>#{name}</i>"]
    summary << "(#{original_author})" if original_author
    summary << "#{author}" if author 
    summary.join(" ")
  end
end

class Entry < Sequel::Model
  many_to_one :entry, :class => Entry

  one_to_many :members, :class => Member
  one_to_many :references, :class => Reference
  one_to_many :synonyms, :class => Synonym
  one_to_many :images, :class => Image
  one_to_many :distribution, :class => Distribution

  def real_distribution
    @real_distribution ||= distribution.select { |d| d.distribution && d.distribution != "-" }
  end

  def summary
    summary = [short]
    summary << "(#{original_author})" if original_author
    summary << "#{author}" if author 
    summary.join(" ")
  end

  def short(format = :html)
    case format
    when :html
      summary = ["<i>#{name}</i>"]
      summary << "subsp. <i>#{subspecies}</i>" if subspecies
      summary << "var. <i>#{variety}</i>" if variety
      summary << "aff. <i>#{affinis}</i>" if affinis
      summary << "<i>#{specifier}</i>" if specifier
    when :text
      summary = [name]
      summary << "subsp. #{subspecies}" if subspecies
      summary << "var. #{variety}" if variety
      summary << "aff. #{affinis}" if affinis
      summary << "#{specifier}" if specifier
    end
    summary.join(" ").gsub(/_/, '').gsub(/\]$/, '')
  end

  def to_json(*a)
    {
      :id => paf_id,
      :name => name,
      :ranking => ranking,
      :images => images,
      :short => short(:text),
      :gbif => gbif_id,
      :last => children.empty?
    }.to_json(*a)
  end

  def html
    self[:html].gsub(/\n+/, '<br><br>').gsub(/\*\*\*+(.+?)\*\*\*/, '<b>\1</b>') rescue ""
  end

  def children
    Entry.where(:parent => paf_id)
  end

  def before_save
    prefix = nil
    self.html = htmlize(notes)
    self.childless = children.empty?
    super
  end

  def species
    name.capitalize.gsub(/\s*\(.+\)/, '').gsub(/\s/, '_')
  end

  def htmlize(text)
    text.to_s.gsub(/\[(.+?)\]/) do |match|
      name = $1.dup
      prefix = name[/^.+?(?=\s)/] if name[/^\p{Upper}(?!\.)/]
      prefixed = prefix ? name.gsub(/^\p{Upper}\./, prefix) : nil
      if e = Entry[:name => name]
        e.id == id ? "<i>#{name}</i>" : "<a class='paf' href='/#{e.paf_id}'>#{name}</a>"
      elsif prefixed && e = Entry[:name => prefixed]
        e.id == id ? "<i>#{name}</i>" : "<a class='paf' href='/#{e.paf_id}'>#{name}</a>"
      else
        "<i>#{name}</i>"
      end
    end
  end
end

