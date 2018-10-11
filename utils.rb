require 'json'

class Utils
  attr_reader :challenge_select, :challenge_translate
  def initialize(browser)
    @browser = browser
    @challenge_translate = 'challenge challenge-translate'
    @challenge_select = 'challenge challenge-select'
  end

  def detect_question_type
    text_area = @browser.div(data_test: /challenge challenge-*/)
    case text_area.data_test
    when challenge_translate
      :challenge_translate
    when challenge_select
      :challenge_select
    else
      abort 'Unknown challenge'
    end
  end

  def create_language_db(lang)
    puts "creating DB for language #{lang}"
    db = {}
    db[lang.to_s] = {}

    span_skills = @browser.execute_script("return document.querySelectorAll('span._378Tf, span._3qO9M, span._33VdW')")
    # span_skills = @browser.spans(class: %w[_378Tf _3qO9M _33VdW])
    puts "#{span_skills.count} skills found "
    span_skills.each do |skill|
      db[lang.to_s][skill.inner_html] = {}
    end

    json_db = JSON.generate db

    File.open('db.json', 'w+') do |line|
      line.puts json_db
    end
  end

  def exists_language_db(lang)
    db = ''
    File.open('db.json', 'r').each do |line|
      db << line
    end
    db = JSON.parse db
    !db[lang.to_s].nil?
  end

  def load_language_db(lang)
    db = ''
    File.open('db.json', 'r').each do |line|
      db << line
    end
    db = JSON.parse db
    db[lang.to_s]
  end

  def study_language(lang, db)
    # loop through all skills testing them out
    # db.each do |skill|
    #   @browser.span(innerhtml: skill).click
    # end
    @browser.span(inner_html: 'Basics 1').click
  end
end
# json example
# {
#     "italian": {
#         "basics-1": {
#             "Le melle sono rosse": "The apples are red"
#         }
#     }
# }
