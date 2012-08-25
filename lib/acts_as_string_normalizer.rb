module Acts

  module StringNormalizer
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods

      require 'text'

      def acts_as_string_normalizer(options={})
        include Acts::StringNormalizer::InstanceMethods
        extend Acts::StringNormalizer::SingletonMethods
      end

      public

      SPACES_PATTERN = regexp('\s+','m')

      def normalize_spaces string
        SPACES_PATTERN.gsub!(string, ' ')
        string
      end

      def decode_entities string
        HTMLEntities.new.decode(string)
      end

      THE_VARIANTS = "The,|The:|The\.|The|Tete|Tie|Tide|Ti1e|Thu|Thf|Thm|Thl|Thk|Thh|This|Teie|Teh:|Teh|Tee|Tiff,|Tine|Tint|Tun|Tin|Tue|Thr|Th|hhe|he|e"
      OFFICES = ["admiral of the fleet",
               "[^(]* commission[^()]*",
               "comptroller [^()]*",
               "(?:#{THE_VARIANTS})? ?(?:lord|temporary)? ?chairman[^()]*",
               "(?:mr\.? )deputy.secretary[^()]*",
               "(?:mr\.? )deputy.chairman[^()]*",
               "(?:mr\.? |aft )?d(?:eput|eupt|eptu|epur)(?:y|h|3),?(?:&#x00B7;|-|\s)?'?S(?:p|n)(?:ea|t a|e i|e a|ae|ee)k(?:e|c)?(?:r|t)?",
               "first [^()]*",
               "(?:#{THE_VARIANTS})? ?first lor(?:e|d)[)]? of the ad-?miralty[^()]*",
               "(?:#{THE_VARIANTS})? ?chancellor[^()]*",
               "(?:#{THE_VARIANTS}|a)? ?lord o(?:f|e) the (?:treasury|terasuey)[^()]*",
               "(?:#{THE_VARIANTS})? ?lord advocate[^()]*",
               "(?:#{THE_VARIANTS})? ?lord chamberlain[^()]*",
               "(?:#{THE_VARIANTS})? ?lord.?c[her]e?[ae]n[cgo]elll?[oc][rbe][^()]*",
               "(?:#{THE_VARIANTS})? ?lord mayor[^()]*",
               "(?:#{THE_VARIANTS})? ?lord president[^()]*",
               "(?:#{THE_VARIANTS})? ?lord\.? p[er]ivy,? seal[^()]*",
               "(?:#{THE_VARIANTS})? ?lord speaker[^()]*",
               "(?:#{THE_VARIANTS})? ?lord steward[^()]*",
               "(?:#{THE_VARIANTS})? ?parliamentary[^()]*",
               "(?:#{THE_VARIANTS})? ?solicitor[^()]*",
               "madam,? [^()]*",
               "(?:mr\.?|#{THE_VARIANTS})? ?(?:prime |The..rime )?minist?er[^()]*",
               "(?:mr.? )?speaker[^()]*",
               "(?:#{THE_VARIANTS})? ?(?:parliamentary.)?(?:under.)?secretary(?: of state [(f]or)?[^()]*",
               "mr\. secretary",
               "paymaster general",
               "treasurer[^()]*",
               "vice.chamberlain[^()]*",
               "t?he (?!(?:earl|lord|countess|duke|marquis|marques|rev\.|reverend))[^()]*" ]

      DEPTS = ['home office', 'scottish office', 'services', 'lord scottish office']


      TITLE_HONORIFICS = ["baron", "baroness", "earl", "lord", 'marquess', 'marquis']
      
      HONORIFICS = ['admiral hon\. sir', 'admiral sir',
                    'admiral',  'air commodore', 'air vice-marshall',
                    'brigadier-general sir', 'brigadier-general',  'brigadier sir',
                    "brigadier",
                    'captain hon\.', "captain the right hon\.", "captain lord", 'captain sir',
                    "captain(?! lord)",
                    'colonel hon\.', 'colonel sir', "colonel",
                    'commander hon\.', 'commander sir', "commander", 'commodore',
                    'count', "countess",
                    "dame", "dr", "duke",
                    'field marshal sir', 'flight lieut',
                    'general hon\. sir', "general sir", "general",
                    'group captain hon\.',  'group captain',
                    'hon\. captain', 'hon\. colonel', 'hon\. sir', 'hon\. vice-admiral', 'hon\.',
                    "lady",'lieut-commander', 'lieut-general', 'lieut-general sir',
                    'lieut-colonel hon\.', 'lieut-colonel sir', 'lieut-colonel', "lieutenant-colonel",
                    'lieutenant', "lieut",
                    'lord viscount', 
                    'major-general hon\. sir', 'major-general', 'major-general sir',
                    'major hon\. sir', 'major hon\.',  'major sir', "major",
                    'master of',
                    "miss", "mr",
                    "mr\. secretary",
                    "mrs", "ms",
                    'professor sir', 'professor',
                    'rear-admiral sir ', "rear-admiral",
                    'reverend dr', 'reverend', "rev",
                    "sir", 'squadron leader', 'sub-lieutenant', "the right honourable",
                    'very reverend dr ', 'vice-admiral sir ',  'vice-admiral',
                    "viscount", 'viscountess',
                    'wing commander sir', "wing commander"] + TITLE_HONORIFICS

      NAME_WORD = '(?:|\w|-|\'|[A-Z]\.(?:[A-Z]\.)?)+'

      TITLES = ['baron of',
                'countess of',
                'duchess of',
                "duke of",
                "earl of",
                "lord archbishop of",
                "lord bishop of",
                "viscount of",
                "marquis of",
                "marquess of",
                "prince of"]

      LAST_NAME_TITLES = ["baroness",
                          "baron",
                          "earl",
                          "lord",
                          "viscount",
                          "the marquess",
                          'marquis']

      FEMALE_DEGREES  = {'baron' => 'baroness', 
                         'lord'  => 'lady', 
                         'viscount' => 'viscountess', 
                         'count'  => 'countess', 
                         'earl'  => 'countess', 
                         'marquis' => 'marchioness', 
                         'marquess' => 'marchioness',
                         'duke'     => 'duchess', 
                         'prince'  => 'princess'}
      
      MALE_DEGREES = FEMALE_DEGREES.invert
                                 
      FIRST_NAMES = '(' + NAME_WORD + '\.?\s+(?:' + NAME_WORD + '\.?\s+)*?)'

      PLACE_NAME = '((?!the Household)' + NAME_WORD + '(?:,?\s+' + NAME_WORD + ')*)'
      LAST_NAME = '((?:St\s)?' + NAME_WORD + '),?'

      ALL_TITLES = '((?:' + THE_VARIANTS + ')? ?(' + TITLES.join('|') + ')\s+(' + PLACE_NAME + '))'
      ALL_LAST_NAME_TITLES = '((' + LAST_NAME_TITLES.join('|') + ')\s+' + LAST_NAME + '\s+of\s+' + PLACE_NAME + ')'
      LORD_ANYTHING = regexp('^(lord)', 'i')

      ALL_HONORIFICS = '((' + HONORIFICS.join('|') + ')\.?)\s+(?!(?:speaker|deputy speaker|\())'
      ALL_HONORIFICS_PATTERN = regexp(ALL_HONORIFICS, 'i')
      JUST_HONORIFIC = '((' + HONORIFICS.join('|') + ')\.?)'
      JUST_HONORIFIC_PATTERN = regexp(JUST_HONORIFIC, 'i')

      ALL_OFFICES = '((?:' + OFFICES.join('|') + ')(?:\((?:' + DEPTS.join('|') + ')\)?)?)'
      ALL_OFFICES_PATTERN = regexp(ALL_OFFICES, 'i')

      HONORIFIC_FIRST_NAME_LAST_NAME =  line_regexp_i(ALL_HONORIFICS + FIRST_NAMES + LAST_NAME)
      HONORIFIC_LAST_NAME =             line_regexp_i(ALL_HONORIFICS + LAST_NAME)
      FIRST_NAME_LAST_NAME =            line_regexp_i('(?!' + ALL_HONORIFICS + ')' + FIRST_NAMES + LAST_NAME)
      OFFICE_FIRST_NAME_LAST_NAME =     line_regexp_i(ALL_OFFICES + ':?\s*\(\s*' + FIRST_NAMES + LAST_NAME + '\)?')
      OFFICE_HONORIFIC_LAST_NAME =      line_regexp_i(ALL_OFFICES + ':?\s*\(\s*' + ALL_HONORIFICS + LAST_NAME + '\)?')
      OFFICE_HONORIFIC_FIRST_LAST =     line_regexp_i(ALL_OFFICES + ':?\s*\(\s*' + ALL_HONORIFICS + FIRST_NAMES + LAST_NAME + '\)?')
      OFFICE_TITLE =                    line_regexp_i(ALL_OFFICES + ':?\s*\(\s*' + ALL_TITLES + '\)?')
      OFFICE_LAST_NAME_TITLE =          line_regexp_i(ALL_OFFICES + ':?\s*\(\s*' + ALL_LAST_NAME_TITLES + ':?\)?')
      OFFICE =                          line_regexp_i(ALL_OFFICES)
      TITLE =                           line_regexp_i(ALL_TITLES)
      LAST_NAME_TITLE =                 line_regexp_i(ALL_LAST_NAME_TITLES)
      FIRST_NAME_SPEAKING_FOR_ANOTHER = line_regexp_i(ALL_HONORIFICS + FIRST_NAMES + LAST_NAME + '\s+\(for .*?\)')
      LAST_NAME_SPEAKING_FOR_ANOTHER =  line_regexp_i(ALL_HONORIFICS + LAST_NAME + '\s+\(for .*?\)')
      OFFICE_NAME_CONSTITUENCY =        line_regexp_i("\\*?\s*" + ALL_OFFICES + ':?\s*\(\s*.*?(,.*)\)?')

      HONORIFIC_FIRST_LAST_OFFICE =    regexp('\A' + ALL_HONORIFICS + FIRST_NAMES + LAST_NAME + '\s*\(' + ALL_OFFICES + '\)?', 'i')
      HONORIFIC_LAST_OFFICE =          regexp('\A' + ALL_HONORIFICS + LAST_NAME + '\s*\(' + ALL_OFFICES + '\)?', 'i')

      NON_CONSTITUENCY_WORDS_LIST = [/minister/i,
                                     /leader of the house/i,
                                     /commissioner/i,
                                     /parliamentary/i,
                                     /house of commons/i,
                                     /chamberlain/i,
                                     /chairman/i]
      NON_CONSTITUENCY_WORDS = Regexp.union(*NON_CONSTITUENCY_WORDS_LIST)

      def detect_non_constituency_words string
        return true if NON_CONSTITUENCY_WORDS.match(string)
      end

      def is_office? string
        return true if OFFICE.match string
        return false
      end

      def strip_office_and_constituency string
        if (office_cons_match = OFFICE_NAME_CONSTITUENCY.match(string))
          constituency = /#{Regexp.escape(office_cons_match[2])}/i
          string = string.gsub(constituency, '')
        end
        if (office_string = find_office(string))
          find_office_pattern = /#{Regexp.escape(office_string)}/i
          string = string.gsub(find_office_pattern, '')
        end
        stripped = string.strip
        stripped = strip_brackets(stripped)
        stripped = correct_trailing_punctuation(stripped)
        stripped = correct_leading_punctuation(stripped)
        stripped.strip
      end

      def office_and_name string
        office = find_office(string)
        office = Office.corrected_name(office) if office
        name = strip_office_and_constituency(string)
        name = corrected_name(name)
        name = decode_entities(name)
        [office, name]
      end

      IN_PARENTHESIS = regexp('\A\((.*?)\)\:?\Z')
      FOLLOWED_BY_PARENTHESIS = regexp('(.*?)\(.*?\)')

      def strip_brackets string
        stripped = string.gsub("()", '')
        stripped.strip!
        IN_PARENTHESIS.gsub!(stripped, '\1')
        FOLLOWED_BY_PARENTHESIS.gsub!(stripped, '\1')
        stripped.strip!
        stripped
      end

      def detect_honorifics string
        return true if ALL_HONORIFICS_PATTERN.match string
        return false
      end

      def is_honorific? string
        return true if JUST_HONORIFIC_PATTERN.match string
        return false
      end

      def find_name_part(string, negative_patterns, positive_patterns)
        negative_patterns.each do |pattern|
          if match = pattern.match(string)
            return nil
          end
        end
        positive_patterns.each do |pattern, group|
          if match = pattern.match(string)
            return match[group].strip
          end
        end
        nil
      end

      def find_honorific string
        negative_patterns = [OFFICE_TITLE,
                             OFFICE_LAST_NAME_TITLE,
                             OFFICE]

        positive_patterns = [[HONORIFIC_FIRST_NAME_LAST_NAME, 1],
                             [OFFICE_HONORIFIC_LAST_NAME, 2],
                             [OFFICE_HONORIFIC_FIRST_LAST, 2],
                             [HONORIFIC_FIRST_LAST_OFFICE, 1],
                             [HONORIFIC_LAST_NAME, 1],
                             [HONORIFIC_LAST_OFFICE, 1],
                             [FIRST_NAME_SPEAKING_FOR_ANOTHER, 1],
                             [LAST_NAME_SPEAKING_FOR_ANOTHER, 1]]

        find_name_part(string, negative_patterns, positive_patterns)
      end

      def find_firstname string
        negative_patterns = [OFFICE_TITLE,
                             TITLE,
                             OFFICE_LAST_NAME_TITLE,
                             OFFICE,
                             OFFICE_HONORIFIC_LAST_NAME,
                             HONORIFIC_LAST_NAME, 
                             LAST_NAME_TITLE
                             ]

        positive_patterns = [[HONORIFIC_FIRST_NAME_LAST_NAME, 3],
                             [FIRST_NAME_LAST_NAME, 3],
                             [HONORIFIC_FIRST_LAST_OFFICE, 3],
                             [OFFICE_HONORIFIC_FIRST_LAST, 4],
                             [OFFICE_FIRST_NAME_LAST_NAME, 2],
                             [FIRST_NAME_SPEAKING_FOR_ANOTHER, 3]]

        if !multiple_lastnames.empty?
          negative_patterns << honorific_multiple_lastnames
          positive_patterns.insert(0, [honorific_firstname_multiple_lastnames, 3])
        end

        firstname = find_name_part(string, negative_patterns, positive_patterns)
        firstname = firstname.split(' ')[0] if firstname
        firstname
      end

      def multiple_lastnames
        Person.find_with_multiple_lastnames.map{ |person| person.lastname }
      end

      def honorific_multiple_lastnames 
        regexp("#{ALL_HONORIFICS}(#{multiple_lastnames.join('|')})", 'i')
      end

      def honorific_firstname_multiple_lastnames
        regexp("#{ALL_HONORIFICS}#{FIRST_NAMES}(#{multiple_lastnames.join('|')})", 'i')
      end

      def find_lastname string
        negative_patterns = [OFFICE_TITLE,
                             OFFICE, 
                             TITLE]

        positive_patterns = [[LAST_NAME_TITLE, 3],
                             [OFFICE_LAST_NAME_TITLE, 4],
                             [HONORIFIC_LAST_NAME, 3],
                             [HONORIFIC_FIRST_NAME_LAST_NAME, 4],
                             [FIRST_NAME_LAST_NAME, 4],
                             [OFFICE_FIRST_NAME_LAST_NAME, 3],
                             [OFFICE_HONORIFIC_LAST_NAME, 4],
                             [HONORIFIC_FIRST_LAST_OFFICE, 4],
                             [OFFICE_HONORIFIC_FIRST_LAST, 5],
                             [FIRST_NAME_SPEAKING_FOR_ANOTHER, 4],
                             [LAST_NAME_SPEAKING_FOR_ANOTHER, 3]]

        if !multiple_lastnames.empty?
          positive_patterns.insert(2, [honorific_multiple_lastnames, 3])
          positive_patterns.insert(3, [honorific_firstname_multiple_lastnames, 4])
        end

        find_name_part(string, negative_patterns, positive_patterns)
      end

      def find_office string
        negative_patterns = [LAST_NAME_TITLE]
        positive_patterns = [[ALL_OFFICES_PATTERN, 1]]
        find_name_part(string, negative_patterns, positive_patterns)
      end

      def find_title string
        negative_patterns = []
        positive_patterns = [[OFFICE_TITLE, 2],
                             [OFFICE_LAST_NAME_TITLE, 2],
                             [TITLE, 1],
                             [LAST_NAME_TITLE, 1]]
        title = find_name_part(string, negative_patterns, positive_patterns)
      end
      
      def find_title_degree string
        negative_patterns = []
        positive_patterns = [[OFFICE_TITLE, 3],
                             [OFFICE_LAST_NAME_TITLE, 3],
                             [TITLE, 2],
                             [LAST_NAME_TITLE, 2], 
                             [LORD_ANYTHING, 1]]
        title = find_name_part(string, negative_patterns, positive_patterns)
        title = find_honorific(string) if ! title 
        title
      end
      
      def correct_degree_for_gender(degree, gender)
        gender_hash = (gender == 'M' ? MALE_DEGREES : FEMALE_DEGREES)
        of_suffix = false
        of_pattern = / of$/
        if of_pattern.match(degree)
          degree = degree.gsub(of_pattern, '')
          of_suffix = true
        end
        correct_gender_degree = (gender_hash[degree.downcase] or degree)
        if correct_gender_degree != degree
          correct_gender_degree = correct_gender_degree.titlecase
        end
        correct_gender_degree = correct_gender_degree + " of" if of_suffix
        correct_gender_degree
      end
      
      def title_without_degree(string)
        degree = find_title_degree(string)
        string.gsub(/^(the )?#{degree}/i, '').strip
      end
      
      def find_title_place string
        title = find_title(string)
        return nil unless title
        parts = title_parts(title)
        if parts.size > 1
          return parts[1, parts.size].join(' of ')
        else
          return nil
        end
      end
      
      def title_without_place string
        title = find_title(string)
        return nil unless title
        non_place_part = title_parts(title)[0]
        if /^the/i.match(non_place_part) or non_place_part.split(' ').size == 1
          return nil
        else
          return non_place_part
        end
      end
      
      def find_title_number string
        title_number = regexp '^\d\d?(th|st|nd|rd)(\/\d\d?(th|st|nd|rd))?'
        if match = title_number.match(string)
          match[0]
        else
          nil
        end
      end
      
      def title_without_number(string)
        if title_number = find_title_number(string)
          string.gsub(title_number, '').strip
        else
          string
        end
      end
      
      def title_parts(title)
        title.split(/ of /i)
      end
      
      def alternative_degrees(degree)
        alternatives = [degree]
        alternative_degrees = { 'lord' => 'Baron', 
                                'baron' => 'Lord', 
                                'baroness' => 'Lady', 
                                'lady' => 'Baroness',
                                'marquis' => 'Marquess', 
                                'marquess' => 'Marquis'}
        alternatives << alternative_degrees[degree.downcase]
        extras = []
        alternatives.each do |alternative|
          if !alternative.blank?
            if / of$/.match(alternative)
              extras << alternative.gsub(/ of$/, '')
            else
              extras << "#{alternative} of" 
            end
          end
        end
        (alternatives + extras).compact
      end

      def alternative_titles(degree, title)
        alternatives = [title]
        if minus_place = title_without_place("#{degree} #{title}")
          alternatives << title_without_degree(minus_place)
        end
        alternatives
      end

      START_OR_PARENTHESIS = '(^|\()'

      DOT_HONORIFIC_WITH_COMMA = regexp START_OR_PARENTHESIS + '(Mrs|Mr|Dr),'
      EXTRA_HONORIFIC_PUNCTUATION = regexp '(Sir)(,|\.)\s?'

      LIEUT_COL_VARIANTS = regexp START_OR_PARENTHESIS + '(Lt\.-Col\.|Lieut\.-Colcnel)'
      LIEUT_VARIANTS = regexp START_OR_PARENTHESIS + '(Lieut\.?\s+|Lieut-)'
      BRIGADIER_GEN_VARIANTS = regexp START_OR_PARENTHESIS + '(Brigadier-Genera|Bri&#x0123;adier-General)\s'
      BRIGADIER_VARIANTS = regexp START_OR_PARENTHESIS + '(Bri&#x0123;adier|Bri&#x00A3;adier|Brig\.)\s'
      MAJOR_GEN_VARIANTS = regexp START_OR_PARENTHESIS + '(Major-Gerteral)\s'

      CAPTAIN_VARIANTS = regexp START_OR_PARENTHESIS + '(Capt\.|Captain\.)\s'

      THE_PATTERN = '(T\S\S\S?|PILE|DIE)'
      OF_PATTERN = '(of|o[^f]|OF|C?O[^F])'
      SPACE = '(,|\s|\.)*'

      EARL_PATTERN = '(EA[^R]L|EAR[^L]|EARL|ERAL)(\.|,)?'
      EARL_VARIANTS = regexp START_OR_PARENTHESIS + EARL_PATTERN + ' '
      THE_EARL_OF_VARIANTS = regexp START_OR_PARENTHESIS + THE_PATTERN + SPACE + EARL_PATTERN + SPACE + OF_PATTERN + SPACE

      DUKE_PATTERN = '(D[^U]KE|DUK[^E]|DUKE)(\.|,)?'
      THE_DUKE_OF_VARIANTS = regexp START_OR_PARENTHESIS + THE_PATTERN + SPACE + DUKE_PATTERN + SPACE + OF_PATTERN + SPACE

      MARQUESS_PATTERN = 'MARQUE.SS?'
                          # MARQUEES
      MARQUESS_VARIANTS = regexp START_OR_PARENTHESIS + MARQUESS_PATTERN + SPACE
      THE_MARQUESS_OF_VARIANTS = regexp START_OR_PARENTHESIS + THE_PATTERN + SPACE + MARQUESS_PATTERN + SPACE + OF_PATTERN + SPACE

      LORD_BISHOP_PATTERN = 'LORD BISHOP'
      THE_LORD_BISHOP_VARIANTS = regexp START_OR_PARENTHESIS + THE_PATTERN + SPACE + LORD_BISHOP_PATTERN + SPACE + OF_PATTERN + SPACE

      BARONESS_VARIANTS = regexp START_OR_PARENTHESIS + '(Baroness;)\s'

      BARONESS_PATTERN = 'BA(R|P\. )O.ESSS?\s'
      BARONESS_OF_VARIANTS = regexp START_OR_PARENTHESIS + BARONESS_PATTERN + SPACE + '([A-Z]+)\s' + OF_PATTERN
      CAPITALIZED_BARONESS_VARIANTS = regexp START_OR_PARENTHESIS + BARONESS_PATTERN

      BISHOP_VARIANTS = regexp "'?BISHOP "
      ARCHBISHOP_VARIANTS = regexp 'AR[^C]HBISHOP '

      LORD_ARCHBISHOP_PATTERN = 'LORD ARCHBISHOP'
      THE_LORD_ARCHBISHOP_VARIANTS = regexp START_OR_PARENTHESIS + THE_PATTERN + SPACE + LORD_ARCHBISHOP_PATTERN + SPACE + OF_PATTERN + SPACE

      HON_MEMBERS_VARIANTS = regexp '^(Hor?n\.?,?\s*?Memh?b?ers|Hon\.\sMembes|Hon\.\sHembers|Hon Members|lion\. Members)'

      LORD_VARIANTS = regexp START_OR_PARENTHESIS + '((LRD|LO[^R]D|LORID|LORI\)|LOR[^D]|LOAN|L[^O]RD|LORD\)|LORD\.|LORD,|L\sORD)'+SPACE+'|LORD\.?(?!\s))|LORD,\s|LORD\)\s'
      TITLECASE_LORD_PATTERN = START_OR_PARENTHESIS + '(Lord\.|Lo[^r]d|L[^o]rd|Lords|Loan|Lose|Loup|Log?in|Lon|Loran|Lora|Logo|Loma|Loge|Lo\S\S\)|Lotto|Loon|Lotus|Lofty|Long)\s'
      TITLECASE_LORD_VARIANTS = regexp TITLECASE_LORD_PATTERN
      TITLECASE_LORD_VARIANTS_PLUS_CAPITALIZED_NAME = regexp TITLECASE_LORD_PATTERN + '([^a-z]*)$'

      AN_HON_MEMBER_VARIANTS = regexp '^(An lion\. Member|An\. Hon\. Member|An Hon Member)'
      HON_MEMBER_VARIANTS = regexp '^(Hon\sMember)'
      SEVERAL_HON_MEMBER_VARIANTS = regexp '^((Sereval|Sevaral|Several\/|Several\.|Severaln) Hon\. Members|Several Hon|Several (lion|Hen|Don|114m)\. Members|Several hon\.Members|Several-hon\. Members)'
      NOBLE_LORD_VARIANTS = regexp '^(A NOME LORD|A NOELS LORD)'
      SEVERAL_NOBLE_LORD_VARIANTS = regexp '^(Several NOBLE LORD|Several NOBLE Loans)'

      COLONEL_VARIANTS = regexp START_OR_PARENTHESIS + '(Col\.)\s'
      AIR_COMMODORE_VARIANTS = regexp START_OR_PARENTHESIS + '(Air-Commodore)\s'
      REAR_ADMIRAL_VARIANTS = regexp START_OR_PARENTHESIS + 'Rea(r|d)(-|\s)Admiral\s'
      WING_COMMANDER_VARIANTS = regexp START_OR_PARENTHESIS + 'Wing-Commander\s'
      ST_VARIANTS = regexp '(?:\s|\A)(S[tT])\.\s?'
      LORD_ST_VARIANTS = regexp START_OR_PARENTHESIS + '(LORD\sST)\s'
      REVEREND_VARIANTS = regexp START_OR_PARENTHESIS + '(Rev\s|Rev\.?,\s|Reverend\s|Rev\.(?!\s))'
      DR_VARIANTS = regexp START_OR_PARENTHESIS + '((Dr0\.)\s|Dr\.\s|Dr\.)'
      VISCOUNT_VARIANTS = regexp START_OR_PARENTHESIS + '(Visc?oun?t(,|\.)?|Viscourrr)\s'
      CAPITALIZED_VISCOUNT_VARIANTS = regexp START_OR_PARENTHESIS + '(V|D)(I|1|T|L)(S-|S|K)?C?I?(O|UO)?\S\S\S\S?\S?(,|\.)?\s'
      VISCOUNT_ST_VARIANTS = regexp START_OR_PARENTHESIS + 'VISCOUNTST\s'

      UPCASE_MR_VARIANTS = regexp START_OR_PARENTHESIS + 'MR\.(?!\s)|MR\. '
      MRS_VARIANTS = regexp START_OR_PARENTHESIS + '((Mrs[;:]|Mrs\.?,?|Mrs\.\.)\s|Mrs\.(?!\s))'
      MADAM_VARIANTS = regexp START_OR_PARENTHESIS + '(Madem|Madame|Madam:|Madam\.|Madam,)\s'

      MR_VARIANTS = regexp START_OR_PARENTHESIS + 'Mr\.\s*?\>|((M r\.|I\. Mr\.|Mr\.,|Mr\.\.|Mr:|Mr;|Ur\.|Mr,|Mi\.|Me\.|Mir\.|Mr\.|Mr&#x00B7;)\s)|Mr\.-|Mr\.:|Mr\.(?!\s)'

      ATTORNEY_GENERAL_VARIANTS = regexp '\A(ATTORNEY GENERAL)'
      CHANCELLOR_EXCHEQUER_VARIANTS = regexp '\A(THE CHANCELLOR or THE EXCHEQUER|THE CHANCELLOE OF THE EXCHEQUER)\Z'
      LORD_PRIVY_SEAL_VARIANTS = regexp '^(THE LORD PR.VY,? .EAL|The Lord. Privy Seal)'
      PRIVY_SEAL_SEC_STATE_VARIANTS = regexp '\A(THE LORD PEIVY SEAL AND SECRETARY OF STATE FOB THE COLONIES)\Z'
      SECRETARY_OF_STATE_VARIANTS = regexp '(SECRETARY OF ST ATE)'
      DEPUTY_PM_VARIANTS = regexp '\A(The Deputy. Prime Minister)\Z'
      PARL_SECRETARY_VARIANTS = regexp '\A(THE PARLIAMENTARY SECRETAR OF)'
      SOL_GEN_IRELAND_VARIANTS = regexp  '(SOLICITOR GENER?E?AL FOB?R? IRELA\.?ND)\Z'
      SOL_GEN_SCOTLAND_VARIANTS = regexp '(SOLICITOR GENERAL FOR SCOTLAND)\Z'
      LORD_OF_TREASURY_VARIANTS = regexp '\A(A LORD OF THE TERASUEY|A LORD OE THE TREASURY)\Z'
      LORD_OF_ADMIRALTY_VARIANTS = regexp '\A(THE FIEST LORD OF THE ADMIRALTY|THE FIRST LORE\) OF THE AD-MIRALTY)\Z'
      LORD_CHANCELLOR_VARIANTS = regexp '\A(THE LORDCHANCELLOR)\Z'
      UNDER_SECRETARY_VARIANTS = regexp '(UNDEE SECRETA(?:E|R)Y|UNDER SECRETARY|UNDERSECREFARY)'
      TITLECASE_UNDER_SECRETARY_VARIANTS = regexp '(Under-Secretay|Under&#x00B7;Secretary|Under"Secretary|tinder-Secretary)'
      MINISTER_VARIANTS = regexp '\A(H?E MINISTER (.*))\Z'
      MINISTRY_VARIANTS = regexp '(\[MINISTRY)'
      TITLECASE_MINISTER_VARIANTS = regexp '\A(Hhe Miniser (.*))\Z'
      TITLECASE_SOL_GENERAL_VARIANTS = regexp '\A(The Solicitor.General|Solicitor.General)\Z'

      PM_VARIANTS = regexp '\A(The\]' + "'" + 'rime Minister)\Z'
      DEPUTY_SPEAKER_VARIANTS = regexp '(Mr. D(?:eput|eupt|eptu|epur)(?:y|h|3),?(?:&#x00B7;|\s)?' + "'" + '?S(?:p|n)(?:ea|t a|e i|e a|ae|ee)k(?:e|c)?(?:r|t)?)'
      SPEAKER_VARIANTS = regexp('(Madam Speaker|MR\.? ?SPEAKER)', 'i')

      ZERO_IN_TEXT = regexp '([A-Z]| )(0+)([A-Z])'
      ONE_IN_TEXT = regexp '([A-Z]| )(1+)([A-Z])'

      def correct_zeros_in_text string
        while (match = ZERO_IN_TEXT.match string)
          oos = ''
          match[2].size.times {|i| oos += 'O'}
          string.sub!(match[0], match[1]+oos+match[3])
        end
        string
      end

      def correct_ones_in_text string
        while (match = ONE_IN_TEXT.match string)
          izes = ''
          match[2].size.times {|i| izes += 'I'}
          string.sub!(match[0], match[1]+izes+match[3])
        end
        string
      end

      THE_OFFICE = regexp('\AThe (.*)\Z', 'i')

      def correct_malformed_offices string
        ATTORNEY_GENERAL_VARIANTS.gsub!(string, 'ATTORNEY-GENERAL')
        LORD_PRIVY_SEAL_VARIANTS.gsub!(string, 'THE LORD PRIVY SEAL')
        SECRETARY_OF_STATE_VARIANTS.gsub!(string, 'SECRETARY OF STATE')
        PRIVY_SEAL_SEC_STATE_VARIANTS.gsub!(string, 'THE LORD PRIVY SEAL AND SECRETARY OF STATE FOR THE COLONIES')
        CHANCELLOR_EXCHEQUER_VARIANTS.gsub!(string, 'THE CHANCELLOR OF THE EXCHEQUER')
        PM_VARIANTS.gsub!(string, 'The Prime Minister')
        DEPUTY_PM_VARIANTS.gsub!(string, 'The Deputy Prime Minister')
        MINISTER_VARIANTS.gsub!(string, 'THE MINISTER \2')
        MINISTRY_VARIANTS.gsub!(string, 'MINISTRY')
        TITLECASE_MINISTER_VARIANTS.gsub!(string, 'The Minister \2')
        TITLECASE_SOL_GENERAL_VARIANTS.gsub!(string, 'The Solicitor-General')
        PARL_SECRETARY_VARIANTS.gsub!(string, 'THE PARLIAMENTARY SECRETARY OF')
        SOL_GEN_IRELAND_VARIANTS.gsub!(string, 'SOLICITOR-GENERAL FOR IRELAND')
        SOL_GEN_SCOTLAND_VARIANTS.gsub!(string, 'SOLICITOR-GENERAL FOR SCOTLAND')
        LORD_OF_TREASURY_VARIANTS.gsub!(string, 'A LORD OF THE TREASURY')
        LORD_OF_ADMIRALTY_VARIANTS.gsub!(string, 'THE FIRST LORD OF THE ADMIRALTY')
        LORD_CHANCELLOR_VARIANTS.gsub!(string, 'THE LORD CHANCELLOR')
        UNDER_SECRETARY_VARIANTS.gsub!(string, 'UNDER-SECRETARY')
        TITLECASE_UNDER_SECRETARY_VARIANTS.gsub!(string, 'Under-Secretary')
        DEPUTY_SPEAKER_VARIANTS.gsub!(string, 'Deputy Speaker')
        SPEAKER_VARIANTS.gsub!(string, 'Speaker')
        THE_OFFICE.gsub!(string, '\1')
        string
      end

      def correct_malformed_honorifics string
        DOT_HONORIFIC_WITH_COMMA.gsub!(string, '\1\2')
        EXTRA_HONORIFIC_PUNCTUATION.gsub!(string, '\1 ')
        LIEUT_COL_VARIANTS.gsub!(string, '\1Lieut-Colonel')
        BRIGADIER_GEN_VARIANTS.gsub!(string, '\1Brigadier-General ')
        BRIGADIER_VARIANTS.gsub!(string, '\1Brigadier ')
        LIEUT_VARIANTS.gsub!(string, '\1Lieut.-')
        MAJOR_GEN_VARIANTS.gsub!(string, '\1Major-General ')
        BARONESS_OF_VARIANTS.gsub!(string, '\1BARONESS \4 OF')
        CAPITALIZED_BARONESS_VARIANTS.gsub!(string, '\1BARONESS ')
        BARONESS_VARIANTS.gsub!(string, '\1Baroness ')
        CAPTAIN_VARIANTS.gsub!(string, '\1Captain ')
        EARL_VARIANTS.gsub!(string, '\1EARL ')
        THE_EARL_OF_VARIANTS.gsub!(string, '\1THE EARL OF ')
        THE_DUKE_OF_VARIANTS.gsub!(string, '\1THE DUKE OF ')
        THE_MARQUESS_OF_VARIANTS.gsub!(string, '\1THE MARQUESS OF ')
        MARQUESS_VARIANTS.gsub!(string, '\1MARQUESS ')
        HON_MEMBERS_VARIANTS.gsub!(string, 'Hon. Members')
        LORD_VARIANTS.gsub!(string, '\1LORD ')
        THE_LORD_BISHOP_VARIANTS.gsub!(string, '\1THE LORD BISHOP OF ')
        ARCHBISHOP_VARIANTS.sub!(string, 'ARCHBISHOP ')
        THE_LORD_ARCHBISHOP_VARIANTS.sub!(string, '\1THE LORD ARCHBISHOP OF ')
        BISHOP_VARIANTS.sub!(string, 'BISHOP ')
        TITLECASE_LORD_VARIANTS_PLUS_CAPITALIZED_NAME.gsub!(string, '\1LORD \3')
        TITLECASE_LORD_VARIANTS.gsub!(string, '\1Lord ')
        AN_HON_MEMBER_VARIANTS.gsub!(string, 'An Hon. Member')
        SEVERAL_HON_MEMBER_VARIANTS.gsub!(string, 'Several Hon. Members')
        SEVERAL_NOBLE_LORD_VARIANTS.gsub!(string, 'Several NOBLE LORDS')
        HON_MEMBER_VARIANTS.gsub!(string, 'Hon. Member')
        NOBLE_LORD_VARIANTS.gsub!(string, 'A NOBLE LORD')
        COLONEL_VARIANTS.gsub!(string, '\1Colonel ')
        AIR_COMMODORE_VARIANTS.gsub!(string, '\1Air Commodore ')
        ST_VARIANTS.gsub!(string, ' \1 ')
        LORD_ST_VARIANTS.gsub!(string, '\1LORD ST ')
        DR_VARIANTS.gsub!(string, '\1Dr ')
        MR_VARIANTS.gsub!(string, '\1Mr ')
        UPCASE_MR_VARIANTS.gsub!(string, '\1MR ')
        MRS_VARIANTS.gsub!(string, '\1Mrs ')
        REAR_ADMIRAL_VARIANTS.gsub!(string, '\1Rear-Admiral ')
        REVEREND_VARIANTS.gsub!(string, '\1Reverend ')
        WING_COMMANDER_VARIANTS.gsub!(string, '\1Wing Commander ')
        VISCOUNT_ST_VARIANTS.sub!(string, '\1VISCOUNT ST ')
        CAPITALIZED_VISCOUNT_VARIANTS.gsub!(string, '\1VISCOUNT ')
        VISCOUNT_VARIANTS.gsub!(string, '\1Viscount ')
        MADAM_VARIANTS.gsub!(string, '\1Madam ')
        LORD_PRIVY_SEAL_VARIANTS.gsub!(string, 'THE LORD PRIVY SEAL')
        string
      end

      def generic_member_description?(string)
        generic_descriptions = ['several hon. members',
                                'several noble lords',
                                'an honourable member',
                                'an hon. member',
                                'hon. members',
                                'hon. member',
                                'a noble lord']
        return true if generic_descriptions.include? string.downcase.strip
      end

      SPACED_HYPHENS = regexp '(\s+-\s*|\s*-\s+)'

      def correct_spaced_hyphens(string)
        SPACED_HYPHENS.gsub!(string,'-')
        string
      end

      HYPHEN_VARIANTS = regexp '(&#x2014;|&#x2013;)'

      def correct_hyphen_variants(string)
        HYPHEN_VARIANTS.gsub!(string,'-')
        string
      end

      LEADING_ARTICLE = regexp('\A(THE|A)\s','i')

      def correct_leading_article(string)
        LEADING_ARTICLE.gsub!(string, '')
        string
      end

      TAG = regexp '<.*>'

      def correct_tags string
        TAG.gsub!(string, '')
        string
      end

      OPEN_BRACKET = '(\[|\()'
      CLOSE_BRACKET = '(\]|\))'
      NON_NAME_SUFFIX =  regexp '( asked .*?| moved| moved, in .*?| rose-| rose| asks?| rose to move.*?| rose to ask.*?| indicated assent| said)\Z'
      BRACKET_SUFFIX_STARTS = ['for ',
                               'on behalf of',
                               'holding answer',
                               'at the bar',
                               'urgent question',
                               'who at this',
                               'seated and covered',
                               'by private notice',
                               'who was',
                               'standing in his place',
                               'pursuant to',
                               'rising from the',
                               'after consulting',
                               'in the clerk']
      BRACKET_NON_NAME_SUFFIX = regexp(OPEN_BRACKET + '(' + BRACKET_SUFFIX_STARTS.join('|') + ').*?' + CLOSE_BRACKET + '?\Z', 'i')

      def correct_non_name_suffix string
        NON_NAME_SUFFIX.gsub!(string, '')
        BRACKET_NON_NAME_SUFFIX.gsub!(string, '')
        string
      end

      NON_NAME_DESCRIPTORS = ["a ministerial peer",
                              "a nationalist member",
                              "a noble baroness",
                              "(my lords,? and )?members of the house of commons",
                              "my hon\. friend",
                              "hon\. members",
                              "an hon\. member",
                              "the hon\. member for",
                              "(several |other )?hon\. member",
                              "a noble lord",
                              "noble lords",
                              "several lords",
                              "several noble lords"]

      NON_NAME_PATT = regexp('\A((' + NON_NAME_DESCRIPTORS.join('|') + ').*)\Z', 'i')

      def remove_non_name_descriptors string
        NON_NAME_PATT.gsub!(string, '')
        string
      end

      TRAILING_PUNCTUATION = regexp '(,|:|\'|\.|\?|;|\||>|\}|\(\)|\\\\|\/|\(|)$'
      UNMATCHED_PAREN = regexp '\A([^(]*)(\))\Z'
      UNMATCHED_SQUARE_PAREN = regexp '\A([^\[]*)(\])\Z'

      def correct_trailing_punctuation string
        string.strip!
        TRAILING_PUNCTUATION.gsub!(string, '')
        UNMATCHED_PAREN.gsub!(string, '\1')
        UNMATCHED_SQUARE_PAREN.gsub!(string, '\1')
        string
      end

      LEADING_PUNCTUATION = regexp '^[^A-Za-z]'

      def correct_leading_punctuation string
        while LEADING_PUNCTUATION.match(string)
          string = string.from(1)
          if string.starts_with?'and'
            string.sub!('and', '')
          end
        end
        if string.ends_with?(')') && (!string.include?('('))
          string = string.chomp(')')
        end
        string
      end

      COLON_IN_TEXT = regexp '([A-Za-z]):([A-Za-z])'
      COMMA_FOR_PERIOD = regexp ' ([A-Z]), '
      ANY_COLON = regexp '(.*):(.*)'

      def correct_bad_punctuation string
        COLON_IN_TEXT.gsub!(string, '\1 \2')
        COMMA_FOR_PERIOD.gsub!(string, ' \1. ')
        string
      end

      def correct_speech_fragment string
        ANY_COLON.sub!(string, '\1')
        string
      end

      QUESTION_PATTERNS = [ regexp('^(Q\.\s*\[\d+\])'),
          regexp('^(\d*\.\s*?\(P\))'),
          regexp('^(and\s\d+\.\s*)'),
          regexp('^(\da\.|\db\.\s*)'),
          regexp('^(Q\.?\s*\d+\.?\s*)'),
          regexp('^(Q\s?l+\d*\.?\s*)'),
          regexp('^(II+\.\s*)'),
          regexp('^(\([a-z]\)\s*)'),
          regexp('^(I\d+\.\s*)'),
          regexp('^(&#x\d+;)')]

      def remove_question_number string
        QUESTION_PATTERNS.each do |pattern|
          if (match = pattern.match(string) )
            string.sub!(match[1], '')
          end
        end
        string
      end

      AND_VARIANTS = regexp('\s(an|arid|amd|and\.|&amp;)\s')
      START_THE_VARIANTS_UPCASE = regexp('\A(' + THE_VARIANTS.upcase + ')\s')
      BRACKET_THE_VARIANTS_UPCASE = regexp('\((' + THE_VARIANTS.upcase + ')\s')
      START_THE_VARIANTS_TITLECASE = regexp('\A(' + THE_VARIANTS + ')\s')
      BRACKET_THE_VARIANTS_TITLECASE = regexp('\((' + THE_VARIANTS + ')\s')

      def correct_common_word_variants string
        AND_VARIANTS.gsub!(string, ' and ')
        START_THE_VARIANTS_UPCASE.gsub!(string, 'THE ')
        BRACKET_THE_VARIANTS_UPCASE.gsub!(string, '(THE ')
        START_THE_VARIANTS_TITLECASE.gsub!(string, 'The ')
        BRACKET_THE_VARIANTS_TITLECASE.gsub!(string, '(The ')
        string
      end

      WESTMINSTER_VARIANTS = regexp('(Westminister)','i') # /(Westminister)/i

      def correct_place_variants string
        WESTMINSTER_VARIANTS.gsub!(string, "Westminster")
        string
      end

      COMPASS_DIRECTION = '(North|South|East|West|Central|Mid)'
      COMPASS_ABBREVIATION = '(N|S|E|W|N\s?E|N\s?W|S\s?E|S\s?W)\.?'
      COMPASS_HYPHEN = regexp("#{COMPASS_DIRECTION}-(.*)")
      TWO_COMPASS = regexp("^#{COMPASS_DIRECTION}.*?(#{COMPASS_DIRECTION}|#{COMPASS_ABBREVIATION})$")
      COMPASS_FIRST = regexp("^(#{COMPASS_DIRECTION}(\s#{COMPASS_DIRECTION})?)\s(.*?)( and .*|$)")
      COMPASS_PART_FIRST = regexp("( and)\s(#{COMPASS_DIRECTION}(\s#{COMPASS_DIRECTION})?)\s(.*)")
      COMMA_COMPASS = regexp("(.*), #{COMPASS_DIRECTION}")
      COMPASS_ABBREV = regexp("(.*?),? #{COMPASS_ABBREVIATION}$")
      COMPASS_FULL = {'N' => 'North',
                      'S' => 'South',
                      'E' => 'East',
                      'W' => 'West',
                      'NE' => 'North East',
                      'NW' => 'North West',
                      'SE' => 'South East',
                      'SW' => 'South West'}

      def correct_compass_variants string
        COMPASS_HYPHEN.gsub!(string, '\1 \2')
        COMPASS_FIRST.gsub!(string, '\5 \1\6') unless TWO_COMPASS.match(string)
        COMMA_COMPASS.gsub!(string, '\1 \2')
        COMPASS_ABBREV.gsub!(string){ |match| match[1] + ' ' + COMPASS_FULL[match[2].gsub(' ', '')]}
        COMPASS_PART_FIRST.gsub!(string, '\1 \6 \2')
        string
      end

      MAX_WORDS_IN_NAME = 20
      SPEECH_STARTS = /:/i

      def correct_long_names string
        if string.split.size > MAX_WORDS_IN_NAME
          if (speech_start_index = string =~ SPEECH_STARTS)
            string = string[0..speech_start_index-1]
          else
            string = ''
          end
        end
        string
      end

      THE_AT_START = regexp('The (.*)')

      def move_the_to_end string
        THE_AT_START.gsub!(string, '\1, The')
        string
      end

      SPACED_INITIALS = regexp('([A-Z]\.)\s+(([A-Z]\.)\s+)(([A-Z]\.)\s+)?')
      def squeeze_initials(string)
        SPACED_INITIALS.gsub!(string, '\1\3\5 ')
        string
      end

      PART_VARIANTS = regexp 'Fart (I|V)'
      THIS_PART_VARIANTS = regexp 'this Fart'
      PART_THEREOF_VARIANTS = regexp 'Fart thereof'

      def correct_part text
        PART_VARIANTS.gsub!(text, 'Part \1')
        THIS_PART_VARIANTS.gsub!(text, 'this Part')
        PART_THEREOF_VARIANTS.gsub!(text, 'Part thereof')
        text
      end


      FACT_VARIANTS = regexp '(these|the|a) fart(s)? (of|that|before)'
      IN_FACT_VARIANTS = regexp '(In|in) fart'

      def correct_fact text
        FACT_VARIANTS.gsub!(text, '\1 fact\2 \3')
        IN_FACT_VARIANTS.gsub!(text, '\1 fact')
        text
      end

      def corrected_name name
        name = String.new(name)
        name = correct_spaced_hyphens(name)
        name = correct_hyphen_variants(name)
        name = remove_question_number(name)
        name = correct_zeros_in_text(name)
        name = correct_ones_in_text(name)
        name = correct_leading_punctuation(name)
        name = correct_malformed_honorifics(name)
        name = correct_non_name_suffix(name)
        name = correct_trailing_punctuation(name)
        name = correct_bad_punctuation(name)
        name = correct_common_word_variants(name)
        name = correct_place_variants(name)
        name = remove_non_name_descriptors(name)
        name = correct_long_names(name)
        name = correct_speech_fragment(name)
        name = squeeze_initials(name)
        name.strip
      end

    end

    module InstanceMethods

      def calculate_edit_distances(options)
        self.class.calculate_edit_distances(self, options)
      end

      def nearest_name_ids(options={:threshold => 2, :include_self => true})
        neighbours = []
        distances = calculate_edit_distances(options)
        distance_keys = distances.keys.sort
        distance_keys.each {|distance| neighbours += distances[distance] }
        neighbours
      end

      def calculate_merge_candidates(options={})
        options[:threshold] = 1
        options[:include_self] = false
        sort_by = options[:sort_by] || :name
        nearest_names = self.class.find(nearest_name_ids(options))
        nearest_names = nearest_names.map{|instance| [instance, instance.send(sort_by)]}
        nearest_names = nearest_names.sort{|a,b| b[1] <=> a[1] }
        # strip down to ids for serialization
        nearest_names.map{|instance, metric| [instance.id, metric] }
      end

    end

    module SingletonMethods

      def calculate_edit_distances(current, options)
        threshold = options[:threshold]
        include_self = options[:include_self]
        sort_by = options[:sort_by] || :name
        @instances = nil if options[:requery]
        distances = Hash.new{ |hash, key| hash[key] = [] }

        @instances ||= find(:all).sort{|a,b| b.send(sort_by) <=> a.send(sort_by) }
        @instances.each do |instance|
          if include_self or current.id != instance.id
            distance = Text::Levenshtein.distance(current.name, instance.name)
            if !threshold or distance <= threshold
              distances[distance] << instance.id
              return distances if options[:first_by_metric]
            end
          end
        end
        distances
      end
    end
  end
end