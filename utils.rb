require 'json'

class Utils

  def initialize(browser ,lang)
    @browser = browser
    @db = {}
    @lang = lang.to_s
    @answers_learned = 0
  end

  def detect_question_style
    text_area = @browser.div(data_test: /challenge challenge-*/)
    case text_area.data_test
    when 'challenge challenge-translate'
      :challenge_translate
    when 'challenge challenge-select'
      :challenge_select
    when 'challenge challenge-judge'
      :challenge_judge
    else
      abort 'Unknown challenge'
    end
  end

  def extract_question
    script = <<~HEREDOC 
    var question = document.querySelector('span[data-test="hint-token"]')
    if (question !== null)
        return question
    
    var question = document.querySelector('div.KRKEd._2UAIZ._1LyQh')
    
    if (question !== null)
        return question
    
    return null
    HEREDOC
    question = @browser.execute_script(script)
    question.inner_html
  end

  def answer_test_out skill
    # read question
    # check question type (select image, select words...)
    # search for answer on language db
    # use answer if there is one
    # skip and get answer if none is found
    # question = @browser.span(data_test: 'hint-token').inner_html
    # question @browser.div(class: %w[KRKEd _2UAIZ _1LyQh]).inner_html
    loop {
      # break when on feedback screen
      sleep 1
      break if @browser.execute_script('return document.querySelector("div._2xGPj") != null')
      question = extract_question
      question_style = detect_question_style
      puts "question : #{question}"
      puts "question style : #{question_style}"
      answer = @db[@lang][skill][question]
      puts "answer : #{if answer.nil? then 'No registered answer' else answer end}"
      if answer.nil? 
        learn_answer question, skill
        @answers_learned += 1
        update_language_db #if @answers_learned == 5 
        @browser.button(data_test: 'player-next').click
      else
        apply_answer answer, question_style
        @browser.button(data_test: 'player-next').click
      end
    }
  end

  def learn_answer question, skill
    @browser.button(data_test: 'player-skip').click 
    answer = @browser.div(class: '_34Ym5').span.span.inner_html
    puts "learning answer : #{answer}"
    @db[@lang][skill][question] = answer 
  end

  def apply_answer answer, question_style
    case question_style
    when :challenge_translate
      script = <<~HEREDOC 
      return document.querySelector('div[data-test="challenge-translate-input"]') === null
      HEREDOC
      if @browser.execute_script script
        words = @browser.buttons(class: %w[iNLw3 _1mSJd])
        words_hash = {}
        words.each do |w|
          words_hash[w.inner_html] = w
        end
        
        answer.split(' ').each do |w|
          w = w.chomp('.') 
          puts "selecting  '#{w}'"
          words_hash[w].click
        end
        
      else
        @browser.textarea(data_test: 'challenge-translate-input').set answer
      end
    when :challenge_select
      puts "apply answer : challenge_select"
    when :challenge_judge
      puts "apply answer : challenge_judge" 
      options = @browser.divs(data_test: 'challenge-judge-text')
      options.each do |o|
        if o.inner_html == answer
          o.click
        end
      end
    else
      abort "Unknown challenge : #{question_style}"
    end
    @browser.button(data_test: 'player-next').click
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
    @db = JSON.parse db
  end

  def update_language_db
    json_db = JSON.generate @db
    File.open('db.json', 'w') do |line|
      line.puts json_db
    end
  end

  def study_language(lang)
    load_language_db(lang)
    # loop through all skills testing them out
    span_skills = @browser.execute_script("return document.querySelectorAll('span._378Tf, span._3qO9M, span._33VdW')")
    skill_hash = {}
    span_skills.each do |span_skill|
      skill_hash[span_skill.inner_html] = span_skill
    end

    loop {
      skill_hash.keys.each do |skill|
        next if !skill_unlocked? skill_hash[skill]
        skill_hash[skill].click
        @browser.button(class: %w[_1FxPb _1Le6e]).click # click on test out
        @browser.button(data_test: 'player-next').click # confirm test out
        answer_test_out skill
        @browser.button(data_test: 'player-next').click # finish test out of current skill
      end
    }
  end

  # watirElement skill
  def skill_unlocked? skill
    puts "#{skill.inner_html} class is #{skill.class_name}"
    if skill.class_name == "_378Tf _3qO9M _33VdW"
      puts "skill '#{skill.inner_html}' is unlocked"
      true
    else
      puts "skill '#{skill.inner_html}' is locked"
      false
    end
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
