class BillResolver < ExternalReferenceResolver

  BILL_NUMBER = /(\(?No\. (\d+)\.?\)?|\[BILL\.(\d+)\.\])/i
  DESCRIPTOR = '(re-committed)'
  HOUSE_OF_LORDS_SUFFIX = /(<i>)?\[(H\.?L\.?|(<i>)?Lords)(<\/i>)?\](<\/i>)?/
  ARTICLE = '(?:\s|^|>)a|the|any|to|my|no|this'

  PREFIXES = /(?:                         # a non-stored group made up of one of
                \A(?:Draft\s|Formerly\s)? # the start of the string, optionally the word draft or formerly
                |
                the\s(?:draft\s)?         # the word the, optionally the word draft
                |
                >\s*                      # the end of a tag and optional space
              )/ix

  NEGATIVE_STARTS = /(?!                        # negative match - cant have any of the following at this point...
                      (?:#{TITLE_CASE_WORD}?\s*)(?:and\s#{TITLE_CASE_WORD}\s)?[RBHP]l?e[an](?:d|ct)ing\sof\sthe    # Reading or Beading or Heading of the
                      |
                      ^[^\(]*\)
                      |
                      A(?:n,?|nd|ny)?\s   # discard a leading A An, An or And or Any
                      |
                      Committee\sof\sthe
                      |
                      Amendments?\s(?:Paper\s)?(?:of|to|in|for)\s
                      |
                      Amend(?:ing?|ed)\s
                      |
                      \w*\s+in\s+the    # word then in the, e.g. House in the, The House in the
                      |
                      Act\s
                      |
                      After
                      |
                      Again,?\s
                      |
                      Another\s
                      |
                      As\s
                      |
                      Between\s
                      |
                      Ballot\sfor\s
                      |
                      Bill\s(?:and|in)\s
                      |
                      Bills?,\s
                      |
                      Campaign\s(?:to|against)\s
                      |
                      Case\sAgainst\s
                      |
                      Chairman\sof\sthe\s
                      |
                      Clerks?\s(?:to|of)\sthe
                      |
                      Clerk\sof\sSupply\sin\sthe
                      |
                      Committal\sof\s
                      |
                      Committee?\sStages?\s
                      |
                      Committees?\s(?:for|of|and)\s
                      |
                      Commons\sto\sthe
                      |
                      Conservative\s
                      |
                      Consideration\s(?:of|in)\s
                      |
                      Commons'\sAmendments\sto
                      |
                      Debates?\s(?:in|of|on|to)\s
                      |
                      Draft\s
                      |
                      EEC\s(?:of|to)\sthe\s
                      |
                      Effects\sof\s
                      |
                      Exchequer,
                      |
                      Environment\sto\sthe\s
                      |
                      Explanatory\s(?:and\sFinancial\s)?Memorandum\s
                      |
                      (?:First\sLord\sof\sthe\s)?(?:Treasury|Admiralty), 
                      |
                      \w+\s(?:and\s\w+\s)?Readings?\s
                      |
                      First,
                      |
                      Financial\sProvisions\sof\sthe
                      |
                      Financial\sResolution\sfor\sthe
                      |
                      Government,?\s(?:of\sthe|to\sthe|in)\s
                      |
                      Government-
                      |
                      Gracious\sSpeech\s
                      |
                      Guillotine\s(?:for|to|Motion|Resolution)\s
                      |
                      Floor\sof\sthe\sHouse\s(?:for|of|in)\sthe\s
                      |
                      From\s
                      |
                      First\sOrder\sthe\s
                      |
                      Third\sOrder, 
                      |
                      His\s
                      |
                      Home\sDepartment,
                      |
                      Labour\s(?:Front\sBench|Party|Government)
                      |
                      Liberal\sGovernment
                      |
                      I\s
                      |
                      Imperial\sParliament,
                      |
                      In\s
                      |
                      Introduction\sof\s
                      |
                      House,\s
                      |
                      Long\sTitle\sof
                      |
                      Lords,
                      |
                      Lords'\s
                      |
                      Lords\s(?:to|of\sthe)
                      |
                      Lord\sAdvocate,
                      |
                      (?:Lord\sPresident\sof\sthe\s)?Council,
                      |
                      Member\sfor\s
                      |
                      Marshalled\sList\s
                      |
                      Memorandum\s(?:on|of|to)\s
                      |
                      Minister\sof\s\w+\sin\sthe\s
                      |
                      Minister,
                      |
                      Money\sResolutions?\s(?:for|of|to)\s
                      |
                      Motion\sto\sthe\s
                      |
                      My\s
                      |
                      Moved,
                      |
                      Next\s
                      |
                      Notice\sof\sthe\s
                      |
                      Notes\son\s
                      |
                      Notice\sPaper\s
                      |
                      No\s
                      |
                      Now,\s
                      |
                      Official\sReport,?\s
                      |
                      On\s
                      |
                      Opposition\s(?:Front\sBench\s)?(?:in|to|for)\s
                      |
                      Opposition's\s
                      |
                      Orders?\s(?:for|of|Paper)\s
                      |
                      (?:Order\sof\sthe\s)?Day\sfor
                      |
                      Ordered,
                      |
                      Our\s
                      |
                      Paper\sto\sthe\s
                      |
                      Paper,\s
                      |
                      Parts?\s
                      |
                      Petitions?\s(?:for|from|against)\s
                      |
                      Preamble\s
                      |
                      Passing\sof\sthe
                      |
                      Private\sMember'?s?\s
                      |
                      Proceedings\sof\sthe\s
                      |
                      Proposals\sin\sthe\s
                      |
                      Protests?\sAgainst\sthe\s
                      |
                      Provisions\sof\sthe
                      |
                      (?:President\sof\sthe\s)?Board\sof\sTrade(?:,|\sin\sthe)
                      |
                      Prime\sMinister,
                      |
                      Queen's\sSpeech\sthe\s
                      |
                      Remaining\sStages\s
                      |
                      Resolution\s(?:of|to|for)\sthe\s
                      |
                      Royal\sAssent\sto\s
                      |
                      \w+\sReport\sof\sthe\s
                      |
                      Secondly,
                      |
                      Seconder\sof\s
                      |
                      Secretary\sof\sState(?:,|\sin\sthe|\sto\sthe)
                      |
                      Secretary\sof\sState\s(?:for|to)(?:\sthe)?(?:\s\w+){1,2}(?:,|\sin\sthe|\sto\sthe)
                      |
                      Secretary\sto\sthe\sTreasury,
                      |
                      Secretary\sto\sthe\sBoard\sof\sTrade,
                      |
                      Select\sCommittee\sof\sthe
                      |
                      Motion\sfor\s
                      |
                      Session,?\s
                      |
                      Sub-section\s
                      |
                      Section\sof\s
                      |
                      Then\s
                      |
                      Tor(?:y|ies')\s
                      |
                      Title\sof\sthe\s
                      |
                      Turning\sto\s
                      |
                      Ways\sand\sMeans\sResolutions?\sfor\s
                      |
                      Vote\s(?:for|on)\s
                      |
                      Statute\sBook\sthe
                      |
                      Subject\sto\sRoyal\sAssent\s
                      |
                      That\s
                      |
                      Table\sShowing\s
                      |
                      Table\sof\sthe\sHouse\s
                      |
                      Third\sSitting\s
                      |
                      Under\s(?!Secretaries)
                      |
                      White\sPaper\s
                      |
                      Vote\sOffice\sthe\s
                      |
                      Time[-\s]Table\s(?:Motion\s)?for\sthe\s
                      |
                      Report\sStage\s
                      |
                      Under\sPart\s
                      |
                      Your\s
                      |
                      (?:Wednesday|Tuesday|Thursday|Monday|Friday)(?:,|\sfor)
                      |
                      Standing\sCommittee
                      |
                      \w+\s+the                 # one word then the, e.g. Although the
                      |
                      Promoters\sof\sthe
                      |
                      \w*\s*Schedule            # some words then Schedule
                      |
                      \w*\s*Clause              # someword Clause
                      |
                      \w*\sAmendment
                      |
                      Government's              # '
                      |
                      All\sof\s
                      |
                      The\s
                      |
                      This\s
                      |
                      Chief\sSecretary\sof\s
                      |
                      Business\sof\sthe\sHouse
                      |
                      House\s
                      |
                      Explanatory\sNotes\s
                      |
                      Instruction\sto\s
                      |
                      Report\sof\s
                      )
                    /ix

  BILL_PATTERN = /#{PREFIXES}                   # prefixes matched but not kept
                  #{NEGATIVE_STARTS}            # any of these means no match
                 (                              # this group is what is kept
                   (
                     (
                      #{CAPS_WORD}              # an all caps word or
                      |
                      #{TITLE_CASE_WORD}         # a titlecase word
                     )
                   (\s|-)                       # then a space or hyphen
                   )
                   (                            # then
                     (\((?=.*\)))?              # optional open bracket (that has to be closed)
                       (
                        #{CAPS_WORD}            # a caps word
                        |
                        #{TITLE_CASE_WORD}       # or a titlecase word
                        |
                        #{BILL_NUMBER}          # or the bill number
                        |
                        \d\d\d\d                # or a year
                        |
                        #{CONJUNCTION_IN_MATCH} # or a conjunction
                        |
                        #{DESCRIPTOR}           # or a special descriptor like re-committed
                       )
                     \)?                        # optional close bracket
                    (\s|-)                      # a space or hyphen
                   )*?                          # zero or more times
                   (BILL|Bill)(?![A-Za-z])      # then the word bill not bills etc
                   (
                    \.?(&\#x2014;|\s)           # optional trailing fullstop, a dash or a space
                    #{BILL_NUMBER}              # and the bill number
                   )?                           # optionally
                   (
                    \.?\s                       #  optional trailing fullstop, a space
                    #{HOUSE_OF_LORDS_SUFFIX}    # and the house of lords suffix
                   )?                           # optionally
                  )
                  /x


  NEGATIVE_BILL_PATTERN = /(
                       ((#{ARTICLE})\sBill)           # not The Bill, My Bill etc
                       |
                       \s(#{CONJUNCTION_IN_MATCH})\sBill
                       |
                       ,\sBill\Z                    # not Smith, Bill
                       |
                       Average\sCouncil\sTax\sBill
                       |
                       ^Each\s
                       |
                       ^Every\s
                       |
                       ^Baroness\sBill
                       |
                       Another\sBill
                       |
                       (January|February|March|April|May|June|July|August|September|October|November|December)\sBill
                       |
                       ^Chancellor\sof\sthe\sExchequer
                       |
                       \AAmend(ed|ing|ment)\sBill\Z
                       |
                       Draft\sBill
                       |
                       Ian\sBill
                       |
                       Private\sMembers?'?\sBill
                       |
                       Hypothetical\sBill
                       |
                       Lords\sBill
                       |
                       ^One\sBill
                       |
                       ^Original\sBill
                       |
                       ^Second\sBill
                       |
                       ^Repealing\sBill
                       |
                       (^(the\s)?Government\sBill)
                       |
                       's\sBill                     # not someones Bill '
                       |
                       Private\sBill
                       |
                       Mr\sBill$
                       |
                       ^(the\s)?Public\sBill
                       |
                       (the\s)?Unopposed\s(Local\s)?Bill
                       |
                       ^(the\s)?English\sBill
                       |
                       ^(the\s)?Back-Bench\sBill
                      )
                     /ix

  def screening_pattern 
    /(BILL|Bill)(?![A-Za-z])/
  end
  
  def positive_pattern_groups
    [[BILL_PATTERN, 1]]
  end

  def negative_patterns
    [NEGATIVE_BILL_PATTERN]
  end

  ITALIC_TAG = regexp '<\/?i>'

  def self.determine_name_and_number(bill_reference)
    ITALIC_TAG.gsub!(bill_reference, '')

    if (number_match = BILL_NUMBER.match(bill_reference))
      bill_reference.gsub!('&#x2014;', '')
      bill_reference.sub!(BILL_NUMBER, '').strip!
      number = number_match[2] ? number_match[2] : number_match[3]
    end
    bill_reference.chomp!('.')
    bill_reference.squeeze!(' ')
    bill_reference.sub!('[H.L]','[H.L.]')

    [bill_reference, number]
  end

  def name_and_number(bill_reference)
    self.class.determine_name_and_number(bill_reference)
  end

  def mention_attributes
    bill_mentions = []
    each_reference do |reference, start_position, end_position|
      name, number = name_and_number(reference)
      bill_mentions << {:name => name,
                        :number => number,
                        :start_position => start_position,
                        :end_position => end_position}
    end
    bill_mentions
  end

end