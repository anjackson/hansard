require File.dirname(__FILE__) + '/../spec_helper'

describe "a string normalizing class instance" do

  before :all do
    self.class.send(:include, Acts::StringNormalizer)
    self.class.acts_as_string_normalizer
  end
  
  describe "when calculating edit distances" do 

    before do
      @mock_one = mock("model", :name => "woot", :id => 1)
      @mock_two = mock("model", :name => "moot", :id => 2)
      stub!(:name).and_return("boot")
      stub!(:id).and_return(3)
      Text::Levenshtein.stub!(:distance)
      self.class.stub!(:find).with(:all).and_return([@mock_one, @mock_two, self])
    end

    it 'should find all instances of the class' do
      self.class.should_receive(:find).with(:all).and_return([])
      calculate_edit_distances({:requery => true})
    end

    it 'should calculate the Levenshtein distance between its name and the name of each instance' do
      Text::Levenshtein.should_receive(:distance).with("boot", "woot")
      Text::Levenshtein.should_receive(:distance).with("boot", "moot")
      calculate_edit_distances({:requery => true})
    end

    it 'should not calculate a distance for itself if not told to include itself' do
      Text::Levenshtein.should_not_receive(:distance).with("boot", "boot")
      calculate_edit_distances({:requery => true})
    end

    it 'should calculate a distance for itself if told to include itself' do
      Text::Levenshtein.should_receive(:distance).with("boot", "boot")
      calculate_edit_distances({:include_self => true, :requery => true})
    end

    it 'should add the ids of all the instances in lists keyed on distance if no threshold is specified' do
      Text::Levenshtein.stub!(:distance).and_return(342)
      calculate_edit_distances({:requery => true}).should == {342 => [1, 2]}
    end

    it 'should add the ids of all the instances with distances equal to or below the threshold if a threshold is specified' do
      Text::Levenshtein.stub!(:distance).with("boot", "woot").and_return(342)
      Text::Levenshtein.stub!(:distance).with("boot", "moot").and_return(3)
      calculate_edit_distances({:threshold => 3, :requery => true }).should == {3 => [2]}
    end

  end

  describe "when getting the ids of instances with names nearest to its own" do

    it 'should ask for the edit distances, passing the options it has been given' do
      options = {:include_self => false, :threshold => 20}
      should_receive(:calculate_edit_distances).with(options).and_return({})
      nearest_name_ids(options)
    end

    it 'should return a list of the calculated edit distances, sorted by ascending distance' do
      stub!(:calculate_edit_distances).and_return({1 => [6,5,4], 2 => [3,2,1]})
      nearest_name_ids({}).should == [6,5,4,3,2,1]
    end

  end

  describe "a string normalizing class instance, when calculating merge candidates" do
    
    it 'should find the models with the nearest names to it' do
      should_receive(:nearest_name_ids).and_return([23, 21])
      mock = mock("instance", :null_object => true, :id => 4)
      self.class.should_receive(:find).with([23,21]).and_return([mock, mock])
      calculate_merge_candidates
    end

    it 'should set a threshold of 1' do
      stub!(:name).and_return("aaaaaaaa")
      should_receive(:nearest_name_ids).with(:threshold => 1,
                                             :include_self => false).and_return([])
      self.class.stub!(:find).and_return([])
      calculate_merge_candidates
    end

    it 'should return a list of model id, contribution count pairs, sorted by descending value of the sort method given' do
      stub!(:nearest_name_ids)
      mock_one = mock("instance", :null_object => true, :sort_method => 1, :id => 4)
      mock_two = mock("instance", :null_object => true, :sort_method => 21, :id => 6)
      self.class.stub!(:find).and_return([mock_one, mock_two])
      calculate_merge_candidates(:sort_by => :sort_method).should == [[6, 21], [4, 1]]
    end

  end

  describe " when recognizing honorifics" do

    def should_recognize honorific
      self.class.is_honorific?(honorific).should be_true
    end

    it do
      should_recognize 'MR'
    end

  end

  describe " when decoding entities" do

    it 'should convert "Lembit &#x00D6;pik" to "Lembit Öpik"' do
      self.class.decode_entities("Lembit &#x00D6;pik").should == 'Lembit Öpik'
    end

  end

  describe " when getting firstnames from names" do

    it 'should get "Lembit" from "Lembit Öpik"' do
      self.class.find_firstname('Lembit Öpik').should == 'Lembit'
    end
    
    it 'should get "of ELIBANK" from "MASTER of ELIBANK"' do
      self.class.find_firstname('MASTER of ELIBANK').should be_nil
    end

    it 'should getnil from "Mr Smith"' do
      self.class.find_firstname('Mr Smith').should be_nil
    end

    it 'should get "John" from "John Smith"' do
      self.class.find_firstname('John Smith').should == 'John'
    end

    it 'should get "T.P." from "MR T.P. O\'CONNOR"' do
      self.class.find_firstname('MR T.P. O\'CONNOR').should == 'T.P.'
    end

    it 'should get "A.R.D." from "MR. A.R.D. ELLIOT"' do
      self.class.find_firstname('MR. A.R.D. ELLIOT').should == 'A.R.D.'
    end

    it 'should get "GEORGE" from ""GENERAL SIR GEORGE BALFOUR""' do
      self.class.find_firstname("GENERAL SIR GEORGE BALFOUR").should == 'GEORGE'
    end

    it 'should get nil from "Mr St John-Stevas"' do
      self.class.find_firstname('Mr St John-Stevas').should == nil
    end

    it "should get nil from 'Mr LLOYD GEORGE' if 'Lloyd George' is known as a lastname with multiple parts" do
      multiple = mock_model(Person, :lastname => 'Lloyd George')
      Person.stub!(:find_with_multiple_lastnames).and_return([multiple])
      self.class.find_firstname('Mr LLOYD GEORGE').should be_nil
    end

    it 'should get "H." from "BARON H. DE WORMS" if "De Worms" is known as a lastname with multiple parts' do
      multiple = mock_model(Person, :lastname => 'de Worms')
      Person.stub!(:find_with_multiple_lastnames).and_return([multiple])
      self.class.find_firstname('BARON H. DE WORMS').should == 'H.'
    end

    it 'should get "Robert" from "Mr Robert C. Brown"' do
      self.class.find_firstname('Mr Robert C. Brown').should == "Robert"
    end
  
    it 'should get nil from "Lord Roberts of Llandudno"' do 
      self.class.find_firstname('Lord Roberts of Llandudno').should be_nil
    end
    
    it 'should return "John" for name "John Smith"' do
      self.class.find_firstname( "John Smith").should == "John"
    end

    it 'should return "Hilary" for name "The Secretary of State for International Development (Hilary Benn)"' do
      self.class.find_firstname( "The Secretary of State for International Development (Hilary Benn)").should == "Hilary"
    end

    it 'should return "Alex" for name "The Under-Secretary of State for Energy (Mr. Alex Eadie)"' do
      self.class.find_firstname( "The Under-Secretary of State for Energy (Mr. Alex Eadie)").should == "Alex"
    end

    it 'should return "Frank" for name "Mr. Frank Allaun"' do
      self.class.find_firstname("Mr. Frank Allaun").should == 'Frank'
    end

    it 'should return nil for name "Mr. Benn"' do
      self.class.find_firstname("Mr. Benn").should be_nil
    end

    it 'should return "H. DRUMMOND" for name "SIR H. DRUMMOND WOLFF"' do
      self.class.find_firstname("SIR H. DRUMMOND WOLFF").should == "H."
    end

    it 'should return "O.L." for name "Brigadier O.L. Prior-Palmer"' do
      self.class.find_firstname("Brigadier O.L. Prior-Palmer").should == "O.L."
    end
    
    
    it 'should return "SIDNEY" for name "Captain SIDNEY HERBERT"' do
      self.class.find_firstname("Captain SIDNEY HERBERT").should == "SIDNEY"
    end

    it 'should return "Brian" for name "Mr. Brian O\'Malley (Lord Commissioner of the Treasury)"' do
      self.class.find_firstname("Mr. Brian O'Malley (Lord Commissioner of the Treasury)").should == "Brian"
    end

    it 'should return "EDWARD" for name "Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)"' do
      self.class.find_firstname("Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)").should == "EDWARD"
    end

    it 'should return "Michael" for name "Mr. Deputy Speaker(Sir Michael Lord)"' do
      self.class.find_firstname("Mr. Deputy Speaker(Sir Michael Lord)").should == "Michael"
    end

    it 'should return "Bowen" for name "Mr. Bowen Wells(Lord Commissioner to the Treasury)"' do
      self.class.find_firstname("Mr. Bowen Wells(Lord Commissioner to the Treasury)").should == "Bowen"
    end

    it 'should return nil for name "THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)"' do
      self.class.find_firstname("THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)").should == nil
    end

    it 'should return nil for name "The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)"' do
      self.class.find_firstname("The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)").should == nil
    end

    it 'should return nil for name "The Minister of State for Defence Procurement (Viscount Trenchard)"' do
      self.class.find_firstname("The Minister of State for Defence Procurement (Viscount Trenchard)").should == nil
    end

    it 'should return nil for name "The Prime Minister"' do
      self.class.find_firstname("The Prime Minister").should == nil
    end

    it 'should return nil for name "Mr. LUNN (for Mr. THOMAS WILLIAMS)"' do
      self.class.find_firstname("Mr. LUNN (for Mr. THOMAS WILLIAMS)").should == nil
    end

    it 'should return "ALAN" for name "Mr. ALAN TODD (for Mr. CLARRY)"' do
      self.class.find_firstname("Mr. ALAN TODD (for Mr. CLARRY)").should == "ALAN"
    end

    it 'should return nil for name "MR. SPEAKER"' do
      self.class.find_firstname("MR. SPEAKER").should be_nil
    end

  end
  
  describe 'when giving titles without numbers' do 
    
    it 'should give "Earl of Dalhousie" for "11th Earl of Dalhousie"' do 
      self.class.title_without_number("11th Earl of Dalhousie").should == 'Earl of Dalhousie'
    end
    
    it 'should give "Earl of Selkirk" for "8th/11th Earl of Selkirk"' do 
      self.class.title_without_number("8th/11th Earl of Selkirk").should == 'Earl of Selkirk'
    end
    
    it 'should give "Earl of Selkirk" for "Earl of Selkirk"' do 
      self.class.title_without_number("Earl of Selkirk").should == 'Earl of Selkirk'
    end
  
  end
  
  describe 'when getting numbers from titles' do 
  
    it 'should get "11th" from "11th Earl of Dalhousie"' do 
      self.class.find_title_number('11th Earl of Dalhousie').should == '11th'
    end
    
    it 'should get "28th" from "28th Earl of Crawford and Balcarres"' do 
      self.class.find_title_number('28th Earl of Crawford and Balcarres').should == '28th'
    end
    
    it 'should get "2nd" from "2nd Baron Panmure"' do 
      self.class.find_title_number('2nd Baron Panmure').should == '2nd'
    end
    
    it 'should get "3rd" from "3rd Marquess of Ely"' do 
      self.class.find_title_number('3rd Marquess of Ely').should == '3rd'
    end
    
    it 'should get "8th/11th" from "8th/11th Earl of Selkirk"' do 
      self.class.find_title_number('8th/11th Earl of Selkirk').should == '8th/11th'
    end
    
    it 'should get "1st" from "1st Viscount Tonypandy"' do 
      self.class.find_title_number('1st Viscount Tonypandy').should == '1st'
    end
        
  end
  
  describe 'when getting title degrees from names' do
    
    it 'should get "Viscount of" from "The Deputy Chairman of Committees (The Viscount of Oxfuird)"' do 
      self.class.find_title_degree("The Deputy Chairman of Committees (The Viscount of Oxfuird)").should == 'Viscount of'
    end
    
    it 'should get "Lord" from "Lord Roberts of Llandudno"' do 
      self.class.find_title_degree("Lord Roberts of Llandudno").should == 'Lord'
    end
    
    it 'should get "EARL OF" from "THE EARL OF LYTTON"' do 
      self.class.find_title_degree("THE EARL OF LYTTON").should == "EARL OF"
    end
    
    it 'should return "Baroness" for "The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)"' do 
      self.class.find_title_degree("The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)").should == 'Baroness'
    end
    
    it 'should get "Baron" from "Baron Aberdare of Duffryn"' do 
      self.class.find_title_degree('Baron Aberdare of Duffryn').should == 'Baron'
    end
    
    it 'should get "Lord" from "Lord Abercorn"' do 
      self.class.find_title_degree('Lord Abercorn').should == 'Lord'
    end
    
    it 'should get "Lord" from "Lord Glenurchy, Benederaloch, Ormelie and Weick"' do 
      self.class.find_title_degree('Lord Glenurchy, Benederaloch, Ormelie and Weick').should == 'Lord'
    end
    
    it 'should get "Marquess" from "Marquess Camden"' do 
      self.class.find_title_degree('Marquess Camden').should == 'Marquess'
    end
    
    it 'should get "Marquis" from "Marquis Camden"' do 
      self.class.find_title_degree('Marquis Camden').should == 'Marquis'
    end
    
    it 'should get "Viscount of" from "Viscount of Balwhidder, Glenalmond and Glenlyon"' do 
      self.class.find_title_degree("Viscount of Balwhidder, Glenalmond and Glenlyon").should == 'Viscount of'
    end
    
  end
  
  describe 'when asked for a title without a degree' do 
  
    it 'should return "Abercorn" for "Lord Abercorn"' do 
      self.class.title_without_degree('Lord Abercorn').should == 'Abercorn'
    end
    
    it 'should get "Aberdare of Duffryn" from "Baron Aberdare of Duffryn"' do 
      self.class.title_without_degree('Baron Aberdare of Duffryn').should == 'Aberdare of Duffryn'
    end
    
    it 'should get "LYTTON" from "THE EARL OF LYTTON"' do 
      self.class.title_without_degree("THE EARL OF LYTTON").should == "LYTTON"
    end
  
  end
  
  describe 'when asked to correct a title degree by gender' do
    
    it 'should return "Baroness" for a female Baron' do 
      self.class.correct_degree_for_gender("Baron", "F").should == 'Baroness'
    end
    
    it 'should return "Baroness" for a female Baroness' do 
      self.class.correct_degree_for_gender("Baroness", "F").should == 'Baroness'
    end
    
    it 'should return "Baron" for a male Baroness' do 
      self.class.correct_degree_for_gender("Baroness", "M").should == 'Baron'
    end
    
    it 'should return "Baron" for a male Baron' do 
      self.class.correct_degree_for_gender("Baron", "M").should == 'Baron'
    end
    
    it 'should return "Lord" for a male Lord' do 
      self.class.correct_degree_for_gender("Lord", "M").should == 'Lord'
    end
    
    it 'should get "Baron of" for a male "Baron of"' do 
      self.class.correct_degree_for_gender('Baron of', 'M').should == 'Baron of'
    end
    
    it 'should get "Baroness of" for a female "Baron of"' do 
      self.class.correct_degree_for_gender('Baron of', 'F').should == 'Baroness of'
    end
    
  end
  
  describe 'when asked for alternative degrees' do 
    
    it 'should return "Lord", "Lord of" and "Baron" for "Lord"' do 
      self.class.alternative_degrees("Lord").should == ["Lord", "Baron", "Lord of", "Baron of"]
    end
    
    it 'should return "Earl" and "Earl of" for "Earl"' do 
      self.class.alternative_degrees("Earl").should == ["Earl", "Earl of"]
    end
    
    it 'should return "Earl" and "Earl of" for "Earl of"' do 
      self.class.alternative_degrees("Earl of").should == ["Earl of", "Earl"]
    end
    
    it 'should return "Lady", "Lady of" and "Baroness" for "Lady"' do 
      self.class.alternative_degrees('Lady').should == ['Lady', "Baroness", "Lady of", "Baroness of"]
    end
    
    it 'should return "Marquis", "Marquis of", "Marquess" and "Marquess of" for "Marquis"' do 
      self.class.alternative_degrees('Marquis').should == ["Marquis", "Marquess", "Marquis of", "Marquess of"]
    end
    
  end
  
  describe 'when asked for alternative titles' do 
    
    it 'should return "Attwood" for "Attwood"' do 
      self.class.alternative_titles("Lord", "Attwood").should == ['Attwood']
    end
    
    it 'should return "Attwood" and "Attwood of Hendon" for "Attwood of Hendon"' do 
      self.class.alternative_titles("Lord", "Attwood of Hendon").should == ["Attwood of Hendon", "Attwood"]
    end
    
  end

  describe 'when getting titles from names' do 
  
    it 'should get "The Viscount of Oxfuird" from "The Deputy Chairman of Committees (The Viscount of Oxfuird)"' do 
      self.class.find_title("The Deputy Chairman of Committees (The Viscount of Oxfuird)").should == 'The Viscount of Oxfuird'
    end
  
    it 'should get "Lord Roberts of Llandudno" from "Lord Roberts of Llandudno"' do 
      self.class.find_title('Lord Roberts of Llandudno').should == "Lord Roberts of Llandudno"
    end
    
    it 'should get "THE EARL OF LYTTON" from "THE EARL OF LYTTON"' do
      self.class.find_title("THE EARL OF LYTTON").should == "THE EARL OF LYTTON"
    end
    
    it 'should return "THE EARL OF DONOUGHMORE" for member with name "THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)"' do
      self.class.find_title("THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)").should == "THE EARL OF DONOUGHMORE"
    end

    it 'should return "Baroness Hollis of Heigham" for member with name "The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)"' do
      self.class.find_title("The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)").should == "Baroness Hollis of Heigham"
    end

    it 'should return "Baroness Symons of Vernham Dean" for member with name "The Parliamentary Under-Secretary of State, Foreign and Commonwealth Office (Baroness Symons of Vernham Dean)"' do
      self.class.find_title("The Parliamentary Under-Secretary of State, Foreign and Commonwealth Office (Baroness Symons of Vernham Dean)").should == "Baroness Symons of Vernham Dean"
    end

    it 'should return nil for member with name "The Prime Minister"' do
      self.class.find_title("The Prime Minister").should == nil
    end

    it 'should return nil for member with name "Mr. J. D. Dormand (Lord Commissioner of the Treasury)"' do
      self.class.find_title("Mr. J. D. Dormand (Lord Commissioner of the Treasury)").should == nil
    end

    it 'should return "THE EARL OF EFFINGHAM" for member with name "THE EARL OF EFFINGHAM"' do
      self.class.find_title("THE EARL OF EFFINGHAM").should == "THE EARL OF EFFINGHAM"
    end

    it 'should return "LORD THOMSON OF FLEET" for member with name "LORD THOMSON OF FLEET"' do
      self.class.find_title("LORD THOMSON OF FLEET").should == "LORD THOMSON OF FLEET"
    end

    it 'should return nil for member with name "Mr. LUNN (for Mr. THOMAS WILLIAMS)"' do
      self.class.find_title("Mr. LUNN (for Mr. THOMAS WILLIAMS)").should be_nil
    end

    it 'should return "VISCOUNT CECIL OF THE CHELWOOD" for member with name "VISCOUNT CECIL OF THE CHELWOOD"' do
      self.class.find_title("VISCOUNT CECIL OF THE CHELWOOD").should == "VISCOUNT CECIL OF THE CHELWOOD"
    end

    it 'should return "THE MARQUESS CURZON OF THE KEDLESTON" for member with name "THE MARQUESS CURZON OF THE KEDLESTON"' do
      self.class.find_title("THE MARQUESS CURZON OF THE KEDLESTON").should == "THE MARQUESS CURZON OF THE KEDLESTON"
    end

    it 'should return nil for member with name "Captain AUSTIN HUDSON (Lord of the Treasury)"' do
      self.class.find_title("Captain AUSTIN HUDSON (Lord of the Treasury)").should be_nil
    end

    it 'should return nil for member with name "A LORD OE THE TREASURY (Sir HERBERT MAXWELL,)"' do
      self.class.find_title("A LORD OE THE TREASURY (Sir HERBERT MAXWELL,)").should be_nil
    end

    it 'should return nil for member with name "A LORD OF THE TREASURY (Sir H. MAXWELL,)"' do
      self.class.find_title("A LORD OF THE TREASURY (Sir H. MAXWELL)").should be_nil
    end

    it 'should return "Baroness Chalker of Wallasey" for member with name "The Minister of State, Foreign and Commonwealth Office (Baroness Chalker of Wallasey:)"' do
      self.class.find_title("The Minister of State, Foreign and Commonwealth Office (Baroness Chalker of Wallasey:)").should == "Baroness Chalker of Wallasey"
    end

    it 'should return "TUE EARL OF ONSLOW" for member with name "TUE EARL OF ONSLOW"' do
      self.class.find_title("TUE EARL OF ONSLOW").should == "TUE EARL OF ONSLOW"
    end


  end

  describe ' when getting title locations from names' do 

    it 'should get "Llandudno" from "Lord Roberts of Llandudno"' do 
      self.class.find_title_place('Lord Roberts of Llandudno').should == "Llandudno"
    end
    
    it 'should get "Oxfuird" from "The Deputy Chairman of Committees (The Viscount of Oxfuird)"' do 
      self.class.find_title_place("The Deputy Chairman of Committees (The Viscount of Oxfuird)").should == 'Oxfuird'
    end
    
    it 'should get "LYTTON" from "THE EARL OF LYTTON"' do
      self.class.find_title_place("THE EARL OF LYTTON").should == 'LYTTON'
    end
   
   it 'should get nil from "Lord Rooker"' do
     self.class.find_title_place("Lord Rooker").should be_nil
   end
      
  end
  
  describe 'when getting titles without places' do 
    
    it 'should get "Lord Roberts" from "Lord Roberts of Llandudno"' do 
      self.class.title_without_place('Lord Roberts of Llandudno').should == 'Lord Roberts'
    end
    
    it 'should get nil from "The Viscount of Oxfuird"' do
      self.class.title_without_place('The Viscount of Oxfuird').should be_nil
    end
    
    it 'should get nil from "THE EARL OF LYTTON"' do 
      self.class.title_without_place('THE EARL OF LYTTON').should be_nil     
    end
    
    it 'should return nil for "Earl of Halifax"' do 
      self.class.title_without_place('Earl of Halifax').should be_nil     
    end
  
  end

  describe " when getting lastnames from names" do

    it 'should get "Öpik" from "Lembit Öpik"' do
      self.class.find_lastname('Lembit Öpik').should == 'Öpik'
    end
    
    it 'should get "ELIBANK" from "MASTER of ELIBANK"' do
      self.class.find_lastname('MASTER of ELIBANK').should == 'ELIBANK'
    end

    it 'should get "Smith" from "Mr Smith"' do
      self.class.find_lastname('Mr Smith').should == 'Smith'
    end

    it 'should get "Smith" from "John Smith"' do
      self.class.find_lastname('John Smith').should == 'Smith'
    end

    it 'should get "Buchanan-Smith" from "Mr. Buchanan-Smith"' do
      self.class.find_lastname('Mr. Buchanan-Smith').should == 'Buchanan-Smith'
    end

    it 'should get "St John-Stevas" from "Mr St John-Stevas"' do
      self.class.find_lastname('Mr St John-Stevas').should == 'St John-Stevas'
    end

    it "should get 'LLOYD GEORGE' from 'Mr LLOYD GEORGE' if 'Lloyd George' is known as a lastname with multiple parts" do
      multiple = mock_model(Person, :lastname => 'Lloyd George')
      Person.stub!(:find_with_multiple_lastnames).and_return([multiple])
      self.class.find_lastname('Mr LLOYD GEORGE').should == 'LLOYD GEORGE'
    end

    it 'should get "DE WORMS" from "BARON H. DE WORMS" if "De Worms" is known as a lastname with multiple parts' do
      multiple = mock_model(Person, :lastname => 'de Worms')
      Person.stub!(:find_with_multiple_lastnames).and_return([multiple])
      self.class.find_lastname('BARON H. DE WORMS').should == 'DE WORMS'
    end
    
    it 'should get "PEEL" from "THE FIRST COMMISSIONER OF WORKS (VISCOUNT PEEL)"' do
      self.class.find_lastname("THE FIRST COMMISSIONER OF WORKS (VISCOUNT PEEL)").should == "PEEL"
    end
    
    it 'should get "Amos" from "The Lord President of the Council (Baroness Amos)"' do 
      self.class.find_lastname("The Lord President of the Council (Baroness Amos)").should == 'Amos'
    end
    
    
    it 'should return "Smith" for a member with name "John Smith"' do
      self.class.find_lastname("John Smith").should == "Smith"
    end

    it 'should return "Benn" for a member with name "The Secretary of State for International Development (Hilary Benn)"' do
      self.class.find_lastname("The Secretary of State for International Development (Hilary Benn)").should == "Benn"
    end

    it 'should return "Eadie" for a member with name "The Under-Secretary of State for Energy (Mr. Alex Eadie)"' do
      self.class.find_lastname("The Under-Secretary of State for Energy (Mr. Alex Eadie)").should == "Eadie"
    end

    it 'should return "Allaun" for a member with name "Mr. Frank Allaun"' do
      self.class.find_lastname("Mr. Frank Allaun").should == 'Allaun'
    end

    it 'should return "Benn" for a member with name "Mr. Benn"' do
      self.class.find_lastname("Mr. Benn").should == "Benn"
    end

    it 'should return "Prior-Palmer" for a member with name "Brigadier O. L. Prior-Palmer"' do
      self.class.find_lastname("Brigadier O. L. Prior-Palmer").should == "Prior-Palmer"
    end

    it 'should return "O\'Malley" for a member with name "Mr. Brian O\'Malley (Lord Commissioner of the Treasury)"' do
      self.class.find_lastname("Mr. Brian O'Malley (Lord Commissioner of the Treasury)").should == "O'Malley"
    end

    it 'should return "FITZROY" for a member with name "Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)"' do
      self.class.find_lastname("Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)").should == "FITZROY"
    end

    it 'should return "Lord" for a member with name "Mr. Deputy Speaker(Sir Michael Lord)"' do
      self.class.find_lastname("Mr. Deputy Speaker(Sir Michael Lord)").should == "Lord"
    end

    it 'should return "Wells" for a member with name "Mr. Bowen Wells(Lord Commissioner to the Treasury)"' do
      self.class.find_lastname("Mr. Bowen Wells(Lord Commissioner to the Treasury)").should == "Wells"
    end

    it 'should return "Jopling" for a member with name "The Minister of Agriculture, Fisheries and Food (Mr. Michael Jopling"' do
      self.class.find_lastname("The Minister of Agriculture, Fisheries and Food (Mr. Michael Jopling").should == "Jopling"
    end

    it 'should return nil for a member with name "THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)"' do
      self.class.find_lastname("THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)").should == nil
    end

    it 'should return "Hollis" for member with name "The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)"' do
      self.class.find_lastname("The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)").should == "Hollis"
    end

    it 'should return "Symons" for member with name "The Parliamentary Under-Secretary of State, Foreign and Commonwealth Office (Baroness Symons of Vernham Dean)"' do
      self.class.find_lastname("The Parliamentary Under-Secretary of State, Foreign and Commonwealth Office (Baroness Symons of Vernham Dean)").should == "Symons"
    end

    it 'should return nil for member with name "The Prime Minister"' do
      self.class.find_lastname("The Prime Minister").should == nil
    end

    it 'should return "LUNN" for member with name "Mr. LUNN (for Mr. THOMAS WILLIAMS)"' do
      self.class.find_lastname("Mr. LUNN (for Mr. THOMAS WILLIAMS)").should == "LUNN"
    end

    it 'should return "TODD" for member with name "Mr. ALAN TODD (for Mr. CLARRY)"' do
      self.class.find_lastname("Mr. ALAN TODD (for Mr. CLARRY)").should == "TODD"
    end

    it 'should return "Peart" for member with name "The Lord President of the Council and Leader of the House of Commons (Mr Fred Peart)"' do
      self.class.find_lastname("The Lord President of the Council and Leader of the House of Commons (Mr Fred Peart)").should == "Peart"
    end

    it 'should return nil for member with name "MR. SPEAKER"' do
      self.class.find_lastname("MR. SPEAKER").should be_nil
    end

    it 'should return nil for member with name "Mr. Secretary Walker,"' do
      self.class.find_lastname("Mr. Secretary Walker,").should == "Walker"
    end

  end

  describe " when getting honorifics from name" do
    
    it 'should get "MASTER of" from "MASTER of ELIBANK"' do
      self.class.find_honorific('MASTER of ELIBANK').should == 'MASTER of'
    end

    it "should get 'Mr' from 'Mr LLOYD GEORGE' if 'Lloyd George' is known as a lastname with multiple parts" do
      multiple = mock_model(Person, :lastname => 'Lloyd George')
      Person.stub!(:find_with_multiple_lastnames).and_return([multiple])
      self.class.find_honorific('Mr LLOYD GEORGE').should == 'Mr'
    end

    it 'should get "BARON" from "BARON H. DE WORMS" if "De Worms" is known as a lastname with multiple parts' do
      multiple = mock_model(Person, :lastname => 'de Worms')
      Person.stub!(:find_with_multiple_lastnames).and_return([multiple])
      self.class.find_honorific('BARON H. DE WORMS').should == 'BARON'
    end
  
    it 'should not raise an error when some multiple lastnames have unicode parts' do 
      multiple = mock_model(Person, :lastname => 'du Pré')
      Person.stub!(:find_with_multiple_lastnames).and_return([multiple])
      self.class.find_honorific('Mr du Pré').should == 'Mr'
    end

    it 'should return "Baroness" for "The Parliamentary Under-Secretary of State, Department of Health (Baroness Hayman)"' do 
      self.class.find_honorific("The Parliamentary Under-Secretary of State, Department of Health (Baroness Hayman)").should == 'Baroness'
    end
    
    it 'should return "Baroness" for "The Lord President of the Council (Baroness Amos)"' do 
      self.class.find_honorific("The Lord President of the Council (Baroness Amos)").should == 'Baroness'
    end
    
    
    it 'should return "Mr." for name "Mr. Frank Allaun"' do
      self.class.find_honorific("Mr. Frank Allaun").should == 'Mr.'
    end

    it 'should return "Mr." for name "Mr. Benn"' do
      self.class.find_honorific("Mr. Benn").should == 'Mr.'
    end

    it 'should return "Mr." for name "The Under-Secretary of State for Energy (Mr. Alex Eadie)"' do
      self.class.find_honorific("The Under-Secretary of State for Energy (Mr. Alex Eadie)").should == 'Mr.'
    end

    it 'should return nil for name "John Smith"' do
      self.class.find_honorific("John Smith").should be_nil
    end

    it 'should return nil for name "The Secretary of State for International Development (Hilary Benn)"' do
      self.class.find_honorific("The Secretary of State for International Development (Hilary Benn)").should be_nil
    end

    it 'should return "Mr." for name "Mr. Brian O\'Malley (Lord Commissioner of the Treasury)"' do
      self.class.find_honorific("Mr. Brian O'Malley (Lord Commissioner of the Treasury)").should == "Mr."
    end

    it 'should return "Captain the Right Hon." for name "Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)"' do
      self.class.find_honorific("Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)").should == "Captain the Right Hon."
    end

    it 'should return "Sir" for name "Mr. Deputy Speaker(Sir Michael Lord)"' do
      self.class.find_honorific("Mr. Deputy Speaker(Sir Michael Lord)").should == "Sir"
    end

    it 'should return "Ms." for name "The Solicitor-General (Ms. Harriet Harman)"' do
      self.class.find_honorific("The Solicitor-General (Ms. Harriet Harman)").should == "Ms."
    end

    it 'should return nil for name "THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)"' do
      self.class.find_honorific("THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)").should == nil
    end

    it 'should return nil for name "The Parliamentary Secretary, Lord Chancellor\'s Department (Yvette Cooper)"' do
      self.class.find_honorific("The Parliamentary Secretary, Lord Chancellor's Department (Yvette Cooper)").should == nil
    end
    
    it 'should return nil for name "The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)"' do
      self.class.find_honorific("The Parliamentary Under-Secretary of State, Department for Work and Pensions (Baroness Hollis of Heigham)").should == nil
    end

    it 'should return nil for name "The Prime Minister"' do
      self.class.find_honorific("The Prime Minister").should == nil
    end

    it 'should return "Mr." for name "Mr. LUNN (for Mr. THOMAS WILLIAMS)"' do
      self.class.find_honorific("Mr. LUNN (for Mr. THOMAS WILLIAMS)").should == "Mr."
    end

    it 'should return "Mr." for name "Mr. ALAN TODD (for Mr. CLARRY)"' do
      self.class.find_honorific("Mr. ALAN TODD (for Mr. CLARRY)").should == "Mr."
    end

    it 'should return nil for name "MR. SPEAKER"' do
      self.class.find_honorific("MR. SPEAKER").should be_nil
    end

    it 'should return "THE RIGHT HONOURABLE" for name "MR. SPEAKER-ELECT (THE RIGHT HONOURABLE WILLIAM SHEPHERD MORRISON)"' do
      self.class.find_honorific("MR. SPEAKER-ELECT (THE RIGHT HONOURABLE WILLIAM SHEPHERD MORRISON)").should == "THE RIGHT HONOURABLE"
    end

    it 'should return "Captain Lord" for name "Captain Lord STANLEY (Lord of the Treasury)"' do
      self.class.find_honorific("Captain Lord STANLEY (Lord of the Treasury)").should == "Captain Lord"
    end
    
  end
  
  describe 'when getting an office from a string' do 

    it 'should return nil for a name "John Smith"' do
      self.class.find_office("John Smith").should be_nil
    end

    it 'should return "The Secretary of State for International Development" for a name "The Secretary of State for International Development (Hilary Benn)"' do
      self.class.find_office("The Secretary of State for International Development (Hilary Benn)").should == "The Secretary of State for International Development"
    end

    it 'should return "The Under-Secretary of State for Energy" for a name "The Under-Secretary of State for Energy (Mr. Alex Eadie)"' do
      self.class.find_office("The Under-Secretary of State for Energy (Mr. Alex Eadie)").should == "The Under-Secretary of State for Energy"
    end

    it 'should return nil for a name "Mr. Frank Allaun"' do
      self.class.find_office("Mr. Frank Allaun").should be_nil
    end

    it 'should return nil for a name "Mr. Benn"' do
      self.class.find_office("Mr. Benn").should be_nil
    end

    it 'should return "Mr. SPEAKER-ELECT" for a  name "Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)"' do
      self.class.find_office("Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)").should == "Mr. SPEAKER-ELECT"
    end

    it 'should return "Mr. Deputy Speaker" for a name "Mr. Deputy Speaker: (Mr. Harold Walker)"' do
      self.class.find_office("Mr. Deputy Speaker: (Mr. Harold Walker)").should == "Mr. Deputy Speaker"
    end

    it 'should return "The Solicitor-General" for a name "The Solicitor-General (Ms. Harriet Harman)"' do
      self.class.find_office("The Solicitor-General (Ms. Harriet Harman)").should == "The Solicitor-General"
    end

    it 'should return "THE CHAIRMAN OF COMMITTEES" for a name "THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)"' do
      self.class.find_office("THE CHAIRMAN OF COMMITTEES (THE EARL OF DONOUGHMORE)").should == "THE CHAIRMAN OF COMMITTEES"
    end

    it 'should return "The Prime Minister" for a name "The Prime Minister"' do
      self.class.find_office("The Prime Minister").should == "The Prime Minister"
    end

    it 'should return "The Lord President of the Council and Leader of the House of Commons" for a name "The Lord President of the Council and Leader of the House of Commons (Mr. Fred Peart)"' do
      self.class.find_office("The Lord President of the Council and Leader of the House of Commons (Mr. Fred Peart)").should == "The Lord President of the Council and Leader of the House of Commons"
    end

    it 'should return "The Lord Chairman" for a name "The Lord Chairman"' do
      self.class.find_office("The Lord Chairman").should == "The Lord Chairman"
    end

    it 'should return "LORD MAYOR" for a name "MR R. N. FOWLER (LORD MAYOR)"' do
      self.class.find_office("MR R. N. FOWLER (LORD MAYOR)").should == "LORD MAYOR"
    end

    it 'should return "Mr. SPEAKER-ELECT" for a name "Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)"' do
      self.class.find_office("Mr. SPEAKER-ELECT (Captain the Right Hon. EDWARD ALGERNON FITZROY)").should == "Mr. SPEAKER-ELECT"
    end

    it 'should return "The Minister for Children" for a name "The Minister for Children (Margaret Hodge)"' do
      self.class.find_office("The Minister for Children (Margaret Hodge)").should == "The Minister for Children"
    end

    it 'should return nil for a name "Lord Home of the Hirsel"' do
      self.class.find_office("Lord Home of the Hirsel").should be_nil
    end

    it 'should return "The Deputy Chairman of Committees" for a name "The Deputy Chairman of Committees (The Viscount of Oxfuird)"' do
     self.class.find_office("The Deputy Chairman of Committees (The Viscount of Oxfuird)").should == "The Deputy Chairman of Committees"
    end

    it 'should return "MR. SPEAKER" for a name "MR. SPEAKER"' do
     self.class.find_office("MR. SPEAKER").should == "MR. SPEAKER"
    end

    it 'should return nil for a name "VISCOUNT CECIL OF THE CHELWOOD"' do
     self.class.find_office("VISCOUNT CECIL OF THE CHELWOOD").should be_nil
    end

    it 'should return nil for a name "THE MARQUESS CURZON OF THE KEDLESTON"' do
     self.class.find_office("THE MARQUESS CURZON OF THE KEDLESTON").should be_nil
    end

    it 'should return "Lord of the Treasury" for a name "Captain AUSTIN HUDSON (Lord of the Treasury)"' do
     self.class.find_office("Captain AUSTIN HUDSON (Lord of the Treasury)").should == "Lord of the Treasury"
    end

    it 'should return "A LORD OE THE TREASURY (Sir HERBERT MAXWELL,)" for member with name "A LORD OE THE TREASURY (Sir HERBERT MAXWELL,)"' do
      self.class.find_office("A LORD OE THE TREASURY (Sir HERBERT MAXWELL,)").should == "A LORD OE THE TREASURY"
    end

    it 'should return "A LORD OE THE TREASURY" for member with name "A LORD OF THE TREASURY (Sir H. MAXWELL,)"' do
      self.class.find_office("A LORD OF THE TREASURY (Sir H. MAXWELL,)").should == "A LORD OF THE TREASURY"
    end

    it 'should return "A LORD OF THE TERASUEY" for member with name "A LORD OF THE TERASUEY (Sir HERBERT MAXWELL,)"' do
      self.class.find_office("A LORD OF THE TERASUEY (Sir HERBERT MAXWELL,)").should == "A LORD OF THE TERASUEY"
    end

    it 'should return "LORD STEWARD of the HOUSEHOLD" for member with name "EARL SYDNEY (LORD STEWARD of the HOUSEHOLD)"' do
      self.class.find_office("EARL SYDNEY (LORD STEWARD of the HOUSEHOLD)").should == "LORD STEWARD of the HOUSEHOLD"
    end

    it 'should return "Prime Minister" for member with name "Prime Minister"' do
      self.class.find_office("Prime Minister").should == "Prime Minister"
    end

    it 'should return "THE FIEST LORD OF THE ADMIRALTY" for member with name "THE FIEST LORD OF THE ADMIRALTY"' do
      self.class.find_office("THE FIEST LORD OF THE ADMIRALTY").should == "THE FIEST LORD OF THE ADMIRALTY"
    end

    it 'should return "THE CHANCELLOE OF THE EXCHEQUER" for member with name "THE CHANCELLOE OF THE EXCHEQUER"' do
      self.class.find_office("THE CHANCELLOE OF THE EXCHEQUER").should == "THE CHANCELLOE OF THE EXCHEQUER"
    end

    it 'should return "The UNDEE SECRETAEY of STATE foe the COLONIES" for member with name "The UNDEE SECRETAEY of STATE foe the COLONIES"' do
      self.class.find_office("The UNDEE SECRETAEY of STATE foe the COLONIES").should == "The UNDEE SECRETAEY of STATE foe the COLONIES"
    end

    it 'should return "Aft Deputy Speaker (Mr. Michael J. Martin)" for member with name "Aft Deputy Speaker"' do
      self.class.find_office("Aft Deputy Speaker (Mr. Michael J. Martin)").should == "Aft Deputy Speaker"
    end

    it 'should return "DEPUTY-SPEAKER" for member with name "DEPUTY-SPEAKER"' do
      self.class.find_office("DEPUTY-SPEAKER").should == "DEPUTY-SPEAKER"
    end

    it 'should return "Mr. Depury Speaker" for member with name "Mr. Depury Speaker (Sir Paul Dean)"' do
      self.class.find_office("Mr. Depury Speaker (Sir Paul Dean)").should == "Mr. Depury Speaker"
    end

    it 'should return "Mr. Deptuy Speaker" for member with name "Mr. Deptuy Speaker (Mr. Richard Crawshaw)"' do
      self.class.find_office("Mr. Deptuy Speaker (Mr. Richard Crawshaw)").should == "Mr. Deptuy Speaker"
    end

    it 'should return "Mr. Deputy&#x00B7;Speaker" for member with name "Mr. Deputy&#x00B7;Speaker (Major Milner)"' do
      self.class.find_office("Mr. Deputy&#x00B7;Speaker (Major Milner)").should == "Mr. Deputy&#x00B7;Speaker"
    end

    it 'should return "Mr. Deputy, Speaker" for member with name "Mr. Deputy, Speaker"' do
      self.class.find_office("Mr. Deputy, Speaker").should == "Mr. Deputy, Speaker"
    end

    it 'should return "Mr. Deupty Speaker" for member with name "Mr. Deupty Speaker (Mr. Bernard Weatherill)"' do
      self.class.find_office("Mr. Deupty Speaker (Mr. Bernard Weatherill)").should == "Mr. Deupty Speaker"
    end

    it 'should return "Mr. DeputySpeaker" for member with name "Mr. DeputySpeaker(Mr. BryantGodmanIrvine)"' do
      self.class.find_office("Mr. DeputySpeaker(Mr. BryantGodmanIrvine)").should == "Mr. DeputySpeaker"
    end

    it 'should return "MR DEPUTY SPEAKER" for a name "MR DEPUTY SPEAKER"' do
      self.class.find_office("MR DEPUTY SPEAKER").should == "MR DEPUTY SPEAKER"
    end

    it 'should return "Mr. Deputy \'Speaker" for a name "Mr. Deputy \'Speaker"' do
      self.class.find_office("Mr. Deputy 'Speaker").should == "Mr. Deputy 'Speaker"
    end

    it 'should return "Mr. Deputy Sneaker" for a name "Mr. Deputy Sneaker (Sir Myer Galpern)"' do
      self.class.find_office("Mr. Deputy Sneaker (Sir Myer Galpern)").should == "Mr. Deputy Sneaker"
    end

    it 'should return "Mr. Deputy Spaeker" for a name "Mr. Deputy Spaeker"' do
      self.class.find_office("Mr. Deputy Spaeker").should == "Mr. Deputy Spaeker"
    end

    it 'should return "Mr. Deputy Spe aker" for a name "Mr. Deputy Spe aker"' do
      self.class.find_office("Mr. Deputy Spe aker").should == "Mr. Deputy Spe aker"
    end

    it 'should return "Mr. Deputy Spe iker" for a name "Mr. Deputy Spe iker (Sir Alan Haselhurst)"' do
      self.class.find_office("Mr. Deputy Spe iker (Sir Alan Haselhurst)").should == "Mr. Deputy Spe iker"
    end

    it 'should return "Mr. Deputy Speak" for a name "Mr. Deputy Speak"' do
      self.class.find_office("Mr. Deputy Speak").should == "Mr. Deputy Speak"
    end

    it 'should return "Mr. Deputy Speakcr" for a name "Mr. Deputy Speakcr"' do
      self.class.find_office("Mr. Deputy Speakcr").should == "Mr. Deputy Speakcr"
    end

    it 'should return "Mr. Deputy Speake" for a name "Mr. Deputy Speake (Sir Alan Haselhurst"' do
      self.class.find_office("Mr. Deputy Speake (Sir Alan Haselhurst").should == "Mr. Deputy Speake"
    end

    it 'should return "Mr. Deputy Speeket" for a name "Mr. Deputy Speeket"' do
      self.class.find_office("Mr. Deputy Speeket").should == "Mr. Deputy Speeket"
    end

    it 'should return "Mr. Deputy Spt aker" for a name "Mr. Deputy Spt aker"' do
      self.class.find_office("Mr. Deputy Spt aker").should == "Mr. Deputy Spt aker"
    end

    it 'should return "Mr. Deputh Speaker" for a name "Mr. Deputh Speaker (Mr. Michael Morris)"' do
      self.class.find_office("Mr. Deputh Speaker (Mr. Michael Morris)").should == "Mr. Deputh Speaker"
    end

    it 'should return "Mr. Deputy Secretary" for a name "Mr. Deputy Secretary (Mr. Paul Dean)"' do
      self.class.find_office("Mr. Deputy Secretary (Mr. Paul Dean)").should == "Mr. Deputy Secretary"
    end

    it 'should return "Mr. Deput3 Speaker" for a name "Mr. Deput3 Speaker"' do
      self.class.find_office("Mr. Deput3 Speaker").should == "Mr. Deput3 Speaker"
    end

    it 'should return "Mr. Deputh Speaker" for a name "Mr. Deputh Speaker (Mr. Michael Morris)"' do
      self.class.find_office("Mr. Deputh Speaker (Mr. Michael Morris)").should == "Mr. Deputh Speaker"
    end

    it 'should return "Mr. Prime Minister" for member with name "Mr. Prime Minister"' do
      self.class.find_office("Mr. Prime Minister").should == "Mr. Prime Minister"
    end

    it 'should return "he Prime Minister" for member with name "he Prime Minister"' do
      self.class.find_office("he Prime Minister").should == "he Prime Minister"
    end

    it 'should return "he Deputy Prime Minister" for member with name "he Deputy Prime Minister"' do
      self.class.find_office("he Deputy Prime Minister").should == "he Deputy Prime Minister"
    end

    it 'should return "Mr. Secretary" for member with name "Mr. Secretary Walker,"' do
      self.class.find_office("Mr. Secretary Walker,").should == "Mr. Secretary"
    end

    it 'should return "Mr. Deputy Chairman" for member with name "Mr. Deputy Chairman"' do
      self.class.find_office("Mr. Deputy Chairman").should == "Mr. Deputy Chairman"
    end

    it 'should return "Chairman of the Catering Sub-Committee" for member with name "Mr. Charles Irving (Chairman of the Catering Sub-Committee)"' do
      self.class.find_office("Mr. Charles Irving (Chairman of the Catering Sub-Committee)").should == "Chairman of the Catering Sub-Committee"
    end

    it 'should return "Vice Chamberlain of the Household" for member with name "Mr. James Hamilton (Vice Chamberlain of the Household)"' do
      self.class.find_office("Mr. James Hamilton (Vice Chamberlain of the Household)").should == "Vice Chamberlain of the Household"
    end

    it 'should return "Parliamentary Under-Secretary of State, Department of Health" for member with name "Parliamentary Under-Secretary of State, Department of Health (Baroness Hayman)"' do
      self.class.find_office("Parliamentary Under-Secretary of State, Department of Health (Baroness Hayman)").should == "Parliamentary Under-Secretary of State, Department of Health"
    end

    it 'should return "Madam, Speaker" for member with name "Madam, Speaker"' do
      self.class.find_office("Madam, Speaker").should == "Madam, Speaker"
    end

    it 'should return "THE LORD CEANCELLOR" for member with name "THE LORD CEANCELLOR (VISCOUNT CAVE)"' do
      self.class.find_office("THE LORD CEANCELLOR (VISCOUNT CAVE)").should == "THE LORD CEANCELLOR"
    end

    it 'should return "THE LORD CHAMBERLAIN" for member with name "THE LORD CHAMBERLAIN (THE EARL OF CROMER)"' do
      self.class.find_office("THE LORD CHAMBERLAIN (THE EARL OF CROMER)").should == "THE LORD CHAMBERLAIN"
    end

    it 'should return "THE LORD CHANCELLCR" for member with name "THE LORD CHANCELLCR (LORD SIMONDS)"' do
      self.class.find_office("THE LORD CHANCELLCR (LORD SIMONDS)").should == "THE LORD CHANCELLCR"
    end

    it 'should return "THE LORD CHANCELLLOR" for member with name "THE LORD CHANCELLLOR"' do
      self.class.find_office("THE LORD CHANCELLLOR").should == "THE LORD CHANCELLLOR"
    end

    it 'should return "THE LORD CHANCELLOB" for member with name "THE LORD CHANCELLOB (EARL LOBEBUEN)"' do
      self.class.find_office("THE LORD CHANCELLOB (EARL LOBEBUEN)").should == "THE LORD CHANCELLOB"
    end

    it 'should return "THE LORD CHANCELLOE" for member with name "THE LORD CHANCELLOE (VISCOUNT CAVE)"' do
      self.class.find_office("THE LORD CHANCELLOE (VISCOUNT CAVE)").should == "THE LORD CHANCELLOE"
    end

    it 'should return "THE LORD CHANGELLOR" for member with name "THE LORD CHANGELLOR"' do
      self.class.find_office("THE LORD CHANGELLOR").should == "THE LORD CHANGELLOR"
    end

    it 'should return "THE LORD CHANOELLOR" for member with name "THE LORD CHANOELLOR"' do
      self.class.find_office("THE LORD CHANOELLOR").should == "THE LORD CHANOELLOR"
    end

    it 'should return "THE LORD CHEANCELLOR" for member with name "THE LORD CHEANCELLOR"' do
      self.class.find_office("THE LORD CHEANCELLOR").should == "THE LORD CHEANCELLOR"
    end

    it 'should return "THE LORD CHENCELLOR" for member with name "THE LORD CHENCELLOR"' do
      self.class.find_office("THE LORD CHENCELLOR").should == "THE LORD CHENCELLOR"
    end

    it 'should return "THE LORD CRANCELLOR" for member with name "THE LORD CRANCELLOR"' do
      self.class.find_office("THE LORD CRANCELLOR").should == "THE LORD CRANCELLOR"
    end

    it 'should return "THE LORD CRANCELLOR" for member with name "THE LORD CRANCELLOR"' do
      self.class.find_office("THE LORD CRANCELLOR").should == "THE LORD CRANCELLOR"
    end

    it 'should return "Admiral of the Fleet" for member with name "Admiral of the Fleet Sir Roger Keyes"' do
      self.class.find_office("Admiral of the Fleet Sir Roger Keyes").should == "Admiral of the Fleet"
    end

    it 'should return "THE LORD STEWARD OF THE HOUSEHOLD" for member with name "THE LORD STEWARD OF THE HOUSEHOLD (VISCOUNT FARQUHAR)"' do
      self.class.find_office("THE LORD STEWARD OF THE HOUSEHOLD (VISCOUNT FARQUHAR)").should == "THE LORD STEWARD OF THE HOUSEHOLD"
    end

    it 'should return "Chairman of the Committee of Selection" for member with name "Chairman of the Committee of Selection (Mr. John McWilliam)"' do
      self.class.find_office("Chairman of the Committee of Selection (Mr. John McWilliam)").should == "Chairman of the Committee of Selection"
    end

    it 'should return "Comptroller of Her Majesty\'s Household" for member with name "Mr. Joseph Harper (Comptroller of Her Majesty\'s Household)"' do
      self.class.find_office("Mr. Joseph Harper (Comptroller of Her Majesty's Household)").should == "Comptroller of Her Majesty's Household"
    end

    it 'should return "The]\'rime Minister" for member with name "The]\'rime Minister (Mrs. Margaret Thatcher)"' do
      self.class.find_office("The]'rime Minister (Mrs. Margaret Thatcher)").should == "The]'rime Minister"
    end

    it 'should return "The Minister of State, Foreign and Commonwealth Office" for member with name "The Minister of State, Foreign and Commonwealth Office (Baroness Chalker of Wallasey:)"' do
      self.class.find_office("The Minister of State, Foreign and Commonwealth Office (Baroness Chalker of Wallasey:)").should == "The Minister of State, Foreign and Commonwealth Office"
    end

    it 'should return "E MINISTER WITHOUT PORTFOLIO" for member with name "E MINISTER WITHOUT PORTFOLIO (THE EARL OF DUNDEE)"' do
      self.class.find_office("E MINISTER WITHOUT PORTFOLIO (THE EARL OF DUNDEE)").should == "E MINISTER WITHOUT PORTFOLIO"
    end

    it 'should return "HE MINISTER WITHOUT PORTFOLIO" for member with name "HE MINISTER WITHOUT PORTFOLIO (LORD CHAMPION)"' do
      self.class.find_office("HE MINISTER WITHOUT PORTFOLIO (LORD CHAMPION)").should == "HE MINISTER WITHOUT PORTFOLIO"
    end

    it 'should return "Hhe Miniser of State, Home Office" for member with name "Hhe Miniser of State, Home Office (Mr. Leon Brittan)"' do
      self.class.find_office("Hhe Miniser of State, Home Office (Mr. Leon Brittan)").should == "Hhe Miniser of State, Home Office"
    end

    it 'should return "THE LORD CHANCELLOR" for member with name "THE LORD CHANCELLOR (LORD, MAUGHAM)"' do
      self.class.find_office("THE LORD CHANCELLOR (LORD, MAUGHAM)").should == "THE LORD CHANCELLOR"
    end

    it 'should return "THE LORDCHANCELLOR" for member with name "THE LORDCHANCELLOR (VISCOUNT JOWITT)"' do
      self.class.find_office("THE LORDCHANCELLOR (VISCOUNT JOWITT)").should == "THE LORDCHANCELLOR"
    end

    it 'should return "THE LORD PRIVY, SEAL" for member with name "THE LORD PRIVY, SEAL (VISCOUNT HALIFAX)"' do
      self.class.find_office("THE LORD PRIVY, SEAL (VISCOUNT HALIFAX)").should == "THE LORD PRIVY, SEAL"
    end

    it 'should return "Under-Secretary of State for the Environment" for member with name "Under-Secretary of State for the Environment (Mr. Keith Speed)"' do
      self.class.find_office("Under-Secretary of State for the Environment (Mr. Keith Speed)").should == "Under-Secretary of State for the Environment"
    end

    it 'should return "Tin LORD CHANCELLOR" for member with name "Tin LORD CHANCELLOR"' do
      self.class.find_office("Tin LORD CHANCELLOR").should == "Tin LORD CHANCELLOR"
    end

    it 'should return "The, Solicitor-General" for member with name "The, Solicitor-General"' do
      self.class.find_office("The, Solicitor-General").should == "The, Solicitor-General"
    end

    it 'should return "The: Lord CHANCELLOR" for member with name "The: Lord CHANCELLOR (Viscount Jowitt)"' do
      self.class.find_office("The: Lord CHANCELLOR (Viscount Jowitt)").should == "The: Lord CHANCELLOR"
    end

    it 'should return "Thr Parliamentary Under-Secretary of State for Social Security" for member with name "Thr Parliamentary Under-Secretary of State for Social Security (Miss Ann Widdecombe)"' do
      self.class.find_office("Thr Parliamentary Under-Secretary of State for Social Security (Miss Ann Widdecombe)").should == "Thr Parliamentary Under-Secretary of State for Social Security"
    end

    it 'should return "MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE" for member with name "Tim MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE (LORD CHALFONT)"' do
      self.class.find_office("Tim MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE (LORD CHALFONT)").should == "MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE"
    end

    it 'should return "Tine Minister of State, Privy Council Office" for member with name "Tine Minister of State, Privy Council Office (Mr. John Smith)"' do
      self.class.find_office("Tine Minister of State, Privy Council Office (Mr. John Smith)").should == "Tine Minister of State, Privy Council Office"
    end

    it 'should return "Tine Temporary Chairman" for member with name "Tine Temporary Chairman"' do
      self.class.find_office("Tine Temporary Chairman").should == "Tine Temporary Chairman"
    end

    it 'should return "Tint LORD CHANCELLOR" for member with name "Tint LORD CHANCELLOR"' do
      self.class.find_office("Tint LORD CHANCELLOR").should == "Tint LORD CHANCELLOR"
    end

    it 'should return "Tun MINISTER OF STATE, BOARD OF TRADE" for member with name "Tun MINISTER OF STATE, BOARD OF TRADE (LORD BROWN)"' do
      self.class.find_office("Tun MINISTER OF STATE, BOARD OF TRADE (LORD BROWN)").should == "Tun MINISTER OF STATE, BOARD OF TRADE"
    end

    it 'should return "The. Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs" for member with name "The. Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs(Mr. Elliot Morley)"' do
      self.class.find_office("The. Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs(Mr. Elliot Morley)").should == "The. Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs"
    end

    it 'should return "Th Prime Minister" for member with name "Th Prime Minister"' do
      self.class.find_office("Th Prime Minister").should == "Th Prime Minister"
    end

    it 'should return "TIFF, CHANCELLOR OF THE DUCHY OF LANCASTER" for member with name "TIFF, CHANCELLOR OF THE DUCHY OF LANCASTER (THE EARL OF CRAWFORD)"' do
      self.class.find_office("TIFF, CHANCELLOR OF THE DUCHY OF LANCASTER (THE EARL OF CRAWFORD)").should == "TIFF, CHANCELLOR OF THE DUCHY OF LANCASTER"
    end

    it 'should return "The Attorney-General" for member with name "The Attorney-General (Mr. Samuel Silkin)"' do
      self.class.find_office("The Attorney-General (Mr. Samuel Silkin)").should == "The Attorney-General"
    end

    it 'should return "The Lord. Privy Seal" for member with name "The Lord. Privy Seal (Lord Williams of Mostyn)"' do
      self.class.find_office("The Lord. Privy Seal (Lord Williams of Mostyn)").should == "The Lord. Privy Seal"
    end

    it 'should return "The Solicitor-General" for member with name "The Solicitor-General (Mr. Nicholas Lyell)"' do
      self.class.find_office("The Solicitor-General (Mr. Nicholas Lyell)").should == "The Solicitor-General"
    end

    it 'should return "The Solicitor?General" for member with name "The Solicitor?General (Mr. Ross Cranston)"' do
      self.class.find_office("The Solicitor?General (Mr. Ross Cranston)").should == "The Solicitor?General"
    end

    it 'should return "PARLIAMENTARY SECRETARY, MINISTRY OF HOUSING AND LOCAL GOVERNMENT" for member with name "PARLIAMENTARY SECRETARY, MINISTRY OF HOUSING AND LOCAL GOVERNMENT (LORD KENNET)"' do
      self.class.find_office("PARLIAMENTARY SECRETARY, MINISTRY OF HOUSING AND LOCAL GOVERNMENT (LORD KENNET)").should == "PARLIAMENTARY SECRETARY, MINISTRY OF HOUSING AND LOCAL GOVERNMENT"
    end

    it 'should return "Speaker" for member with name "Speaker"' do
      self.class.find_office("Speaker").should == "Speaker"
    end

    it 'should return "THE FIRST LORE) OF THE AD-MIRALTY" for member with name "THE FIRST LORE) OF THE AD-MIRALTY (VISCOUNT HALL)"' do
      self.class.find_office("THE FIRST LORE) OF THE AD-MIRALTY (VISCOUNT HALL)").should == "THE FIRST LORE) OF THE AD-MIRALTY"
    end

    it 'should return "Paymaster General" for member with name "Paymaster General (The Earl of Caithness)"' do
      self.class.find_office("Paymaster General (The Earl of Caithness)").should == "Paymaster General"
    end

    it 'should return "THE LORD PEIVY SEAL AND SECRETARY OF STATE FOB THE COLONIES" for member with name "THE LORD PEIVY SEAL AND SECRETARY OF STATE FOB THE COLONIES (THE EARL OF CREWE)"' do
      self.class.find_office("THE LORD PEIVY SEAL AND SECRETARY OF STATE FOB THE COLONIES").should == "THE LORD PEIVY SEAL AND SECRETARY OF STATE FOB THE COLONIES"
    end

    it 'should return "The. Parliamentary Under-Secretary of State for Scotland" for member with name "The. Parliamentary Under-Secretary of State for Scotland (Lord James Douglas-Hamilton)"' do
      self.class.find_office("The. Parliamentary Under-Secretary of State for Scotland (Lord James Douglas-Hamilton)").should == "The. Parliamentary Under-Secretary of State for Scotland"
    end

    it 'should return "MR. SPEAKER-ELECT" for member with name "MR. SPEAKER-ELECT (THE RIGHT HONOURABLE WILLIAM SHEPHERD MORRISON),"' do
      self.class.find_office("MR. SPEAKER-ELECT (THE RIGHT HONOURABLE WILLIAM SHEPHERD MORRISON),").should == "MR. SPEAKER-ELECT"
    end

    it 'should return "THEPARLIAMENTARY UNDERSECRETARY OF STATE FOR INDIA AND BURMA" for member with name "THEPARLIAMENTARY UNDERSECRETARY OF STATE FOR INDIA AND BURMA (THE DUKE OF DEVONSHIRE)"' do
      self.class.find_office("THEPARLIAMENTARY UNDERSECRETARY OF STATE FOR INDIA AND BURMA (THE DUKE OF DEVONSHIRE)").should == "THEPARLIAMENTARY UNDERSECRETARY OF STATE FOR INDIA AND BURMA"
    end

    it 'should return "The Secretary of State (or the Home Department" for member with name "The Secretary of State (or the Home Department (Mr. R. A. Butler)"' do
      self.class.find_office("The Secretary of State (or the Home Department (Mr. R. A. Butler)").should == "The Secretary of State (or the Home Department"
    end

    it 'should return "THE JOINT PARLIAMENTARY SECRETARY, [MINISTRY OF TRANSPORT (LORD CHESHAM)" for member with name "THE JOINT PARLIAMENTARY SECRETARY, [MINISTRY OF TRANSPORT"' do
      self.class.find_office("THE JOINT PARLIAMENTARY SECRETARY, [MINISTRY OF TRANSPORT (LORD CHESHAM)").should == "THE JOINT PARLIAMENTARY SECRETARY, [MINISTRY OF TRANSPORT"
    end

    it 'should return "LORD STEWARD of the HOUSEHOLD" for member with name "EARL SYDNEY (LORD STEWARD of the HOUSEHOLD)"' do
      self.class.find_office("LORD STEWARD of the HOUSEHOLD").should == "LORD STEWARD of the HOUSEHOLD"
    end

    it 'should return "THE JOINT PARLIAMENTARY UNDER-SECRETARY OF STATE (HOME OFFICE)" for member with name "THE JOINT PARLIAMENTARY UNDER-SECRETARY OF STATE (HOME OFFICE) (LORD STONHAM)"' do
      self.class.find_office("THE JOINT PARLIAMENTARY UNDER-SECRETARY OF STATE (HOME OFFICE) (LORD STONHAM)").should == "THE JOINT PARLIAMENTARY UNDER-SECRETARY OF STATE (HOME OFFICE)"
    end

    it 'should return "The PARLIAMENTARY UNDER-SECRETARY of STATE (HOME OFFICE)" for member with name "The PARLIAMENTARY UNDER-SECRETARY of STATE (HOME OFFICE) (Lord Belstead)"' do
      self.class.find_office("The PARLIAMENTARY UNDER-SECRETARY of STATE (HOME OFFICE) (Lord Belstead)").should == "The PARLIAMENTARY UNDER-SECRETARY of STATE (HOME OFFICE)"
    end

     it 'should return "The Minister of State (Home Office)" for member with name "The Minister of State (Home Office) (Mr. Mark Carlisle)"' do
       self.class.find_office("The Minister of State (Home Office) (Mr. Mark Carlisle)").should == "The Minister of State (Home Office)"
     end

     it 'should return "THE SECRETARY OF STATE FOR DOMINION AFFAIRS" for member with name "THE SECRETARY OF STATE FOR DOMINION AFFAIRS (LORD CECIL) (Viscount Cranborne)"' do
       self.class.find_office("THE SECRETARY OF STATE FOR DOMINION AFFAIRS (LORD CECIL) (Viscount Cranborne)").should == "THE SECRETARY OF STATE FOR DOMINION AFFAIRS"
     end

     it 'should return "THE MINISTER OF STATE, SCOTTISH OFFICE (LORD SCOTTISH OFFICE (LORD STRATHCLYDE)" for member with name "THE MINISTER OF STATE, SCOTTISH OFFICE (LORD SCOTTISH OFFICE (LORD STRATHCLYDE)"' do
       self.class.find_office("THE MINISTER OF STATE, SCOTTISH OFFICE (LORD SCOTTISH OFFICE").should == "THE MINISTER OF STATE, SCOTTISH OFFICE (LORD SCOTTISH OFFICE"
     end

     it 'should return "THE SECRETARY OF STATE FOR THE COLONIES" for member with name "THE SECRETARY OF STATE FOR THE COLONIES (VISCOUNT CRABORNE) (Lord Cecil)"' do
       self.class.find_office("THE SECRETARY OF STATE FOR THE COLONIES (VISCOUNT CRABORNE) (Lord Cecil)").should == "THE SECRETARY OF STATE FOR THE COLONIES"
     end

     it 'should return "The Under-Secretary of State for Home Affairs and Agriculture (Scottish Office)" for member with name "The Under-Secretary of State for Home Affairs and Agriculture (Scottish Office) (Mr. Alick Buchanan-Smith)"' do
       self.class.find_office("The Under-Secretary of State for Home Affairs and Agriculture (Scottish Office) (Mr. Alick Buchanan-Smith)").should == "The Under-Secretary of State for Home Affairs and Agriculture (Scottish Office)"
     end

     it 'should return "The Under-Secretary of State for Development (Scottish Office)" for member with name "The Under-Secretary of State for Development (Scottish Office) (Mr. George Younger)"' do
       self.class.find_office("The Under-Secretary of State for Development (Scottish Office) (Mr. George Younger)").should == "The Under-Secretary of State for Development (Scottish Office)"
     end

     it 'should return "The Chairman of the Select Committee on House of Commons (Services)" for member with name "The Chairman of the Select Committee on House of Commons (Services) (Mr. Arthur Bottomley)"' do
       self.class.find_office("The Chairman of the Select Committee on House of Commons (Services) (Mr. Arthur Bottomley)").should == "The Chairman of the Select Committee on House of Commons (Services)"
     end
     
  end
  

  describe ' when getting an office and name from a string' do

   it 'should extract and correct the office and name parts' do
      string = 'The Official (Joe Member)'
      self.class.stub!(:find_office).with(string).and_return('The Official')
      self.class.should_receive(:strip_office_and_constituency).with(string).and_return('Joe Member')
      Office.should_receive(:corrected_name).with('The Official').and_return('Official')
      self.class.office_and_name(string).should == ['Official', 'Joe Member']
    end

    it 'should decode HTML entities in the member name' do
      self.class.should_receive(:decode_entities).with('Joe Member').and_return('Joe')
      self.class.office_and_name('Joe Member').should == [nil, 'Joe']
    end

    it 'should return name "Lembit Öpik" and office nil for "Lembit &#x00D6;pik"' do
      self.class.office_and_name('Lembit &#x00D6;pik').should == [nil, 'Lembit Öpik']
    end

    it 'should return name "Mr H.H. ASQUITH" and office "SECRETARY OF STATE FOR THE HOME DEPARTMENT" for "THE SECRETARY OF STATE FOR THE HOME DEPARTMENT (Mr. H. H. ASQUITH, Fife, E.)"' do
      self.class.office_and_name('THE SECRETARY OF STATE FOR THE HOME DEPARTMENT (Mr. H. H. ASQUITH, Fife, E.)').should == ['SECRETARY OF STATE FOR THE HOME DEPARTMENT', 'Mr H.H. ASQUITH']
    end

    it 'should return name "Sir WALTER FOSTER" and office "PARLIAMENTARY SECRETARY TO THE LOCAL GOVERNMENT BOARD" for "THE PARLIAMENTARY SECRETARY TO THE LOCAL GOVERNMENT BOARD (Sir WALTER FOSTER, Derbyshire, Ilkeston)"' do
      self.class.office_and_name('THE PARLIAMENTARY SECRETARY TO THE LOCAL GOVERNMENT BOARD (Sir WALTER FOSTER, Derbyshire, Ilkeston)').should == ['PARLIAMENTARY SECRETARY TO THE LOCAL GOVERNMENT BOARD', 'Sir WALTER FOSTER']
    end

    it 'should return name "Mr CAMPBELL-BANNERMAN" and office "THE SECRETARY OF STATE FOR WAR" for "*THE SECRETARY OF STATE FOR WAR (Mr. CAMPBELL-BANNERMAN, Stirling Burghs)"' do
      self.class.office_and_name('*THE SECRETARY OF STATE FOR WAR (Mr. CAMPBELL-BANNERMAN, Stirling Burghs)').should == ["SECRETARY OF STATE FOR WAR", "Mr CAMPBELL-BANNERMAN"]
    end

    it 'should return name "MR T. SNAPE" and office nil for "*MR. T. SNAPE"' do
      self.class.office_and_name("*MR. T. SNAPE").should == [nil, 'MR T. SNAPE']
    end
  end

  describe " when correcting malformed offices" do

    def should_correct_office name, corrected_name
      self.class.correct_malformed_offices(name).should == corrected_name
    end

    it do
      should_correct_office "MR. SPEAKER", "Speaker"
    end

    it do
      should_correct_office "Mr.Speaker", "Speaker"
    end

    it do
      should_correct_office "Madam Speaker", "Speaker"
    end

    it do
      should_correct_office "Mr. Deputy Speaker", "Deputy Speaker"
    end

    it do
      should_correct_office "Mr. Speaker", "Speaker"
    end

    it do
      should_correct_office "THE JUDGE ADVOCATE GENERAL", "JUDGE ADVOCATE GENERAL"
    end

    it do
      should_correct_office "THE PRIME MINISTER", "PRIME MINISTER"
    end

    it do
      should_correct_office "SOLICITOR GENERAL FOR IRELAND", "SOLICITOR-GENERAL FOR IRELAND"
    end

  end

  describe 'when deciding if a piece of text is a generic member description' do

    def should_be_generic_description(text)
      self.class.generic_member_description?(text).should be_true
    end

    it 'should return true for "Several Hon. Members"' do
      should_be_generic_description('Several Hon. Members')
    end

    it 'should return true for "An Hon. Member"' do
      should_be_generic_description('An Hon. Member')
    end

    it 'should return true for "Hon. Members"' do
      should_be_generic_description('Hon. Members')
    end

    it 'should return true for "Hon. Member"' do
      should_be_generic_description('Hon. Member')
    end

    it 'should return true for "SEVERAL NOBLE LORDS"' do
      should_be_generic_description('SEVERAL NOBLE LORDS')
    end

    it 'should return true for "A NOBLE LORD"' do
      should_be_generic_description('A NOBLE LORD')
    end

  end

  describe " when stripping office and constituency parts from a name" do


    it 'should return "MR R. N. FOWLER (LORD MAYOR)" for "MR R. N. FOWLER (LORD MAYOR)"' do
      self.class.strip_office_and_constituency("MR R. N. FOWLER (LORD MAYOR)").should == "MR R. N. FOWLER"
    end

    it 'should return "The Viscount of Oxfuird" for "The Deputy Chairman of Committees (The Viscount of Oxfuird)"' do
      self.class.strip_office_and_constituency("The Deputy Chairman of Committees (The Viscount of Oxfuird)").should == "The Viscount of Oxfuird"
    end

    it 'should return "Mr. GOSCHEN" for "THE CHANCELLOR OF THE EXCHEQUER (Mr. GOSCHEN,)"' do
      self.class.strip_office_and_constituency("THE CHANCELLOR OF THE EXCHEQUER (Mr. GOSCHEN,)").should == "Mr. GOSCHEN"
    end

    it 'should return "Miss Melanie Johnson" for "The Parliamentary Under-Secretary of State for Health (Miss Melanie Johnson):"' do
      self.class.strip_office_and_constituency("The Parliamentary Under-Secretary of State for Health (Miss Melanie Johnson):").should == 'Miss Melanie Johnson'
    end

    it 'should not throw an error if the office matched contains regular expression special characters' do
      self.class.stub!(:find_office).and_return('*The Commissioner')
      self.class.strip_office_and_constituency('*The Commissioner of Works (Janice Allen)')
    end

  end

  describe " when correcting names" do

    def should_correct_name name, corrected_name
      self.class.corrected_name(name).should == corrected_name
    end

    it 'should match "Mr " to "Mr "' do
      should_correct_name 'Mr Marten', 'Mr Marten'
    end
    it 'should match "(Mr " to "(Mr "' do
      should_correct_name 'The Minister of State for Agriculture, Fisheries and Food (Mr Anthony Stodart)', 'The Minister of State for Agriculture, Fisheries and Food (Mr Anthony Stodart)'
    end
    it 'should match "Mr.," to "Mr ' do
      should_correct_name 'Mr., Freeson', 'Mr Freeson'
    end
    it 'should match "Mr.-" to "Mr ' do
      should_correct_name 'Mr.-Janner', 'Mr Janner'
    end
    it 'should match "Mr.." to "Mr ' do
      should_correct_name 'Mr.. Anthony Stodart', 'Mr Anthony Stodart'
    end
    it 'should match "Mr.:" to "Mr ' do
      should_correct_name 'Mr.:Benn', 'Mr Benn'
    end
    it 'should match "Mr.>" to "Mr ' do
      should_correct_name 'Mr.>Archy Kirkwood', 'Mr Archy Kirkwood'
    end
    it 'should match "Mr.Straw" to "Mr Straw"' do
      should_correct_name "Mr.Straw", "Mr Straw"
    end
    it 'should match "Mr: " to "Mr "' do
      should_correct_name 'Mr: Nott', 'Mr Nott'
    end
    it 'should match "Mr: " to "Mr "' do
      should_correct_name 'Mr; Waldegrave', 'Mr Waldegrave'
    end

    it 'should match "Mr: " to "Mr "' do
      should_correct_name 'M r. John E. Talbot', 'Mr John E. Talbot'
    end

    it 'should match "Mrs " to "Mrs "' do
      should_correct_name 'Mrs Ann Cryer', 'Mrs Ann Cryer'
    end
    it 'should match "(Mrs " to "(Mrs "' do
      should_correct_name 'The Minister for Consumer Affairs (Mrs Sally Oppenheim)', 'The Minister for Consumer Affairs (Mrs Sally Oppenheim)'
    end
    it 'should match "Ms " to "Ms "' do
      should_correct_name 'Ms Ann Cryer', 'Ms Ann Cryer'
    end
    it 'should match "(Ms " to "(Ms "' do
      should_correct_name 'The Minister for Consumer Affairs (Ms Sally Oppenheim)', 'The Minister for Consumer Affairs (Ms Sally Oppenheim)'
    end

    it 'should recognize a name is incorrect if it starts with " character' do
      should_correct_name '"LORD CHORLEY', 'LORD CHORLEY'
    end

    it 'should recognize a name is incorrect if it starts with ! character' do
      should_correct_name '!Ur. Hunt', 'Mr Hunt'
    end
    it 'should recognize a name is incorrect if it starts with — character' do
      should_correct_name '—Mr. Mason', 'Mr Mason'
    end
    it 'should recognize a name is incorrect if it starts with \' character' do
      should_correct_name "'Mr. Pattie", "Mr Pattie"
    end
    it 'should recognize a name is incorrect if it starts with (\d) characters' do
      should_correct_name "(2) Mr. Dorrell", "Mr Dorrell"
    end
    it 'should recognize a name is incorrect if it starts with ( character' do
      should_correct_name "(Dr. Strang", "Dr Strang"
    end
    it 'should strip starting (' do
      self.class.correct_leading_punctuation("(Dr. Strang").should == "Dr. Strang"
    end
    it 'should recognize a name is incorrect if it starts with . character' do
      should_correct_name ".Blunkett", "Blunkett"
    end
    it 'should recognize a name is incorrect if it ends with . character' do
      should_correct_name "EARL DE LA WARR.", "EARL DE LA WARR"
    end
    it 'should recognize a name is incorrect if it ends with > character' do
      should_correct_name "EARL STANHOPE>", "EARL STANHOPE"
    end
    it 'should recognize a name is incorrect if it ends with ) character' do
      should_correct_name "Judd)", "Judd"
    end

    it 'should recognize a name is incorrect if it ends with ( character' do
      should_correct_name "Mr. Anthony Nelson (", "Mr Anthony Nelson"
    end

    it 'should recognize a name is incorrect if it ends with ] character' do
      should_correct_name "Mr. Atkins]", "Mr Atkins"
    end

    it 'should recognize a name is incorrect if it ends with / character' do
      should_correct_name "Mr. Cook/", "Mr Cook"
    end

    it 'should recognize a name is incorrect if it ends with \ character' do
      should_correct_name "Mr. Dalyell\\", "Mr Dalyell"
    end

    it 'should leave () untouched' do
      should_correct_name "Judy Mallaber (Amber Valley)", "Judy Mallaber (Amber Valley)"
    end
    it 'should recognize a name is incorrect if it starts with . and space' do
      should_correct_name ". Blunkett", "Blunkett"
    end
    it 'should recognize a name is incorrect if it starts with digit' do
      should_correct_name "0Mr. Roberts", "Mr Roberts"
    end
    it 'should recognize a name is incorrect if it starts with "I"+digit . and space' do
      should_correct_name "I5. Mr. Tilney", "Mr Tilney"
    end
    it 'should recognize a name is incorrect if it starts with "II." and space' do
      should_correct_name "II. Major-General Sir Alfred Knox", "Major-General Sir Alfred Knox"
    end
    it 'should recognize a name is incorrect if it starts with digit . and space' do
    end
    it 'should match "I. Mr. X" to "Mr X"' do
      should_correct_name 'I. Mr. X', 'Mr X'
    end
    it 'should recognize a name is incorrect if it starts with multiple digits . and space' do
      should_correct_name "10. Mr. Ashley", "Mr Ashley"
    end
    it 'should recognize a name is incorrect if it starts with "89 and 90. "' do
      should_correct_name "89 and 90. Mr. G. Thomas", "Mr G. Thomas"
    end
    it 'should recognize a name is incorrect if it starts with > character' do
      should_correct_name "> Mr. Darling", "Mr Darling"
    end
    it 'should recognize a name is incorrect if it starts with > and digits' do
      should_correct_name ">11. Mr. Rowe", "Mr Rowe"
    end
    it 'should recognize a name incorrect if it ends with :' do
      should_correct_name "A NOBLE LORD:", ""
    end
    it 'should recognize a name is incorrect if it starts with Q and digit' do
      should_correct_name "Q 1. Mr. Greville Janner", "Mr Greville Janner"
    end
    it 'should recognize a name is incorrect if it starts with "Q 1. [147480]" ' do
      should_correct_name "Q 1. [147480] Mr. Henry Bellingham", "Mr Henry Bellingham"
    end
    it 'should recognize a name is incorrect if it starts with Q and digits' do
      should_correct_name "Q10. Mr. Cartwright", "Mr Cartwright"
    end
    it 'should recognize a name is incorrect if it starts with Ql.' do
      should_correct_name "Ql. Mr. Alton", "Mr Alton"
    end
    it 'should recognize a name is incorrect if it starts with Qll.' do
      should_correct_name "Qll. Dr. Harris", "Dr Harris"
    end
    it 'should recognize a name is incorrect if it starts with [' do
      should_correct_name "[MR. SPEAKER", "MR SPEAKER"
    end
    it 'should recognize a name is incorrect if it starts with ]' do
      should_correct_name "]Lord McIntosh of Haringey", "Lord McIntosh of Haringey"
    end
    it 'should recognize a name is incorrect if it starts with _' do
      should_correct_name "_Mr. Nigel Spearing", "Mr Nigel Spearing"
    end
    it 'should recognize a name is incorrect if it starts with expanded unicode, eg "&#x0021;"' do
      should_correct_name "&#x0021;Ur. Hunt", "Mr Hunt"
    end
    it 'should recognize a name is incorrect if it starts with Mr,' do
      should_correct_name "Mr, Nigel Spearing", "Mr Nigel Spearing"
    end

    it 'should recognize a name is incorrect if it starts with Me.' do
      should_correct_name "Me. Deputy Speaker", "Mr Deputy Speaker"
    end

    it 'should recognize a name is incorrect if it starts with Mi.' do
      should_correct_name "Mi. Godber", "Mr Godber"
    end

    it 'should recognize a name is incorrect if it starts with Mir.' do
      should_correct_name "Mir. Redwood", "Mr Redwood"
    end

    it 'should recognize a name is incorrect if it starts with Mr&#x00B7;' do
      should_correct_name "Mr&#x00B7; Stewart", "Mr Stewart"
    end

    it 'should recognize a name is incorrect if it starts with Mrs,' do
      should_correct_name "Mrs, Renée Short", "Mrs Renée Short"
    end

    it 'should recognize a name is incorrect if it starts with Mrs.,' do
      should_correct_name "Mrs., Hart", "Mrs Hart"
    end

    it 'should recognize a name is incorrect if it starts with Mrs.something' do
      should_correct_name "Mrs.Beckett", "Mrs Beckett"
    end

    it 'should recognize a name is incorrect if it starts with Mrs:' do
      should_correct_name "Mrs: Beckett", "Mrs Beckett"
    end

    it 'should recognize a name is incorrect if it starts with Mrs;' do
      should_correct_name "Mrs; Taylor", "Mrs Taylor"
    end

    it 'should recognize a name is incorrect if it starts with Mrs.. ' do
      should_correct_name "Mrs.. Chalker", "Mrs Chalker"
    end

    it 'should recognize a name is incorrect if it starts with Dr,' do
      should_correct_name "Dr, David Owen", "Dr David Owen"
    end
    it 'should recognize a name is incorrect if it starts with Sir,' do
      should_correct_name "Sir, I. Gilmour", "Sir I. Gilmour"
    end
    it 'should recognize a name is incorrect if it ends with ,' do
      should_correct_name "Dame Irene Ward,", "Dame Irene Ward"
    end
    it 'should match "Brigadier -General" to "Brigadier-General"' do
      should_correct_name "Brigadier -General CLIFTON BROWN", "Brigadier-General CLIFTON BROWN"
    end
    it 'should match "Brigadier - General" to "Brigadier-General"' do
      should_correct_name "Brigadier - General Sir HENRY CROFT", "Brigadier-General Sir HENRY CROFT"
    end
    it 'should match "Brigadier - Genera " to "Brigadier-General "' do
      should_correct_name "Brigadier - Genera CLIFTON BROWN", "Brigadier-General CLIFTON BROWN"
    end
    it 'should match "Bri&#x0123;adier" to "Brigadier"' do
      should_correct_name "Bri&#x0123;adier-General BROWN", "Brigadier-General BROWN"
    end
    it 'should match "Bri&#x00A3;adier" to "Brigadier"' do
      should_correct_name "Bri&#x00A3;adier Rayner", "Brigadier Rayner"
    end
    it 'should match "Brig. " to "Brigadier"' do
      should_correct_name "Brig. Prior-Palmer", "Brigadier Prior-Palmer"
    end
    it 'should match "Capt. " to "Captain"' do
      should_correct_name "Capt. Elliot", "Captain Elliot"
    end
    it 'should match "Captain. " to "Captain "' do
      should_correct_name "Captain. CAZALET", "Captain CAZALET"
    end
    it 'should match "Col. " to "Colonel "' do
      should_correct_name 'Col. Beamish', 'Colonel Beamish'
    end
    it 'should match "Dr.Boyson" to "Dr Boyson"' do
      should_correct_name 'Dr.Boyson', 'Dr Boyson'
    end
    it 'should match "Dr0. Kumar" to "Dr Kumar"' do
      should_correct_name 'Dr0. Kumar', 'Dr Kumar'
    end

    describe 'when honorific is "EARL"' do
      it 'should correct "EARL. "' do
        should_correct_name "EARL. CARRINGTON", "EARL CARRINGTON"
      end
      it 'should correct "EAR,"' do
        should_correct_name 'EAR, JELLICOE', 'EARL JELLICOE'
      end
      it 'should correct "EARI,"' do
        should_correct_name 'EARI, DE LA WARR', 'EARL DE LA WARR'
      end
      it 'should correct "EARL,"' do
        should_correct_name 'EARL, DE LA WARR', 'EARL DE LA WARR'
      end
      it 'should correct "EARL."' do
        should_correct_name 'EARL. DE LA WARR', 'EARL DE LA WARR'
      end
      it 'should correct "EAEL "' do
        should_correct_name 'EAEL CAWDOR', 'EARL CAWDOR'
      end
      it 'should correct "EALL "' do
        should_correct_name 'EALL STANHOPE', 'EARL STANHOPE'
      end
      it 'should correct "ERAL ' do
        should_correct_name 'ERAL JELLICOE', 'EARL JELLICOE'
      end
    end

    describe 'when honorific is "THE EARL OF"' do
      it 'should match "THE EARL. "' do
        should_correct_name "THE EARL. OF BUCKINGHAMSHIRE", "THE EARL OF BUCKINGHAMSHIRE"
      end
      it 'should correct "THE EARLOF[A-Z]"' do
        should_correct_name 'THE EARLOFCREWE', 'THE EARL OF CREWE'
      end
      it 'should correct "THE EARL, or"' do
        should_correct_name 'THE EARL, or LYTTON', 'THE EARL OF LYTTON'
      end
      it 'should correct "THK EARL "' do
        should_correct_name "THK EARL OF ONSLOW", "THE EARL OF ONSLOW"
      end
      it 'should correct "THL EARL "' do
        should_correct_name "THL EARL OF SELKIRK", "THE EARL OF SELKIRK"
      end
      it 'should correct "THR EARL "' do
        should_correct_name "THR EARL OF HOME", "THE EARL OF HOME"
      end
      it 'should correct "THU EARL "' do
        should_correct_name "THU EARL OF SWINTON", "THE EARL OF SWINTON"
      end
      it 'should correct "TI1E EARL "' do
        should_correct_name "TI1E EARL OF LONGFORD", "THE EARL OF LONGFORD"
      end
      it 'should correct "TIDE EARL "' do
        should_correct_name "TIDE EARL OF KINNOULL", "THE EARL OF KINNOULL"
      end
      it 'should correct "PILE EARL "' do
        should_correct_name "PILE EARL OF CRAWFORD", "THE EARL OF CRAWFORD"
      end
      it 'should correct "T.HE EARL "' do
        should_correct_name "T.HE EARL OF CREWE", "THE EARL OF CREWE"
      end
      it 'should correct "TER EARL "' do
        should_correct_name "TER EARL OF CRAWFORD", "THE EARL OF CRAWFORD"
      end
      it 'should correct "THB EARL "' do
        should_correct_name "THB EARL OF MEATH", "THE EARL OF MEATH"
      end
      it 'should correct "THE EABL "' do
        should_correct_name "THE EABL OF CLABENDON", "THE EARL OF CLABENDON"
      end
      it 'should correct "THE EAEL "' do
        should_correct_name "THE EAEL OF ONSLOW", "THE EARL OF ONSLOW"
      end
      it 'should correct "THE EAKL "' do
        should_correct_name "THE EAKL OF ANOASTEK", "THE EARL OF ANOASTEK"
      end
      it 'should correct "THE EARL 0F "' do
        should_correct_name "THE EARL 0F CAMPERDOWN", "THE EARL OF CAMPERDOWN"
      end
      it 'should correct "THE EARL.OF "' do
        should_correct_name "THE EARL.OF HALSBURY", "THE EARL OF HALSBURY"
      end
      it 'should correct "TIER EARL "' do
        should_correct_name "TIER EARL OF DARTMOUTH", "THE EARL OF DARTMOUTH"
      end
      it 'should correct "TIIE EARL "' do
        should_correct_name "TIIE EARL OF CREWE", "THE EARL OF CREWE"
      end
      it 'should correct "TILE EARL "' do
        should_correct_name "TILE EARL OF CRAWFORD", "THE EARL OF CRAWFORD"
      end
      it 'should correct "Tim EARL OF " to "THE EARL OF "' do
        should_correct_name "Tim EARL OF DUDLEY", "THE EARL OF DUDLEY"
      end
      it 'should correct "DIE EARL OF "' do
        should_correct_name "DIE EARL OF LISTOWEL", 'THE EARL OF LISTOWEL'
      end
    end

    it 'should match "OF:" to "OF "' do
      should_correct_name 'EARL CURZON OF:KEDLESTON', 'EARL CURZON OF KEDLESTON'
    end
    it 'should match "Hon Member" to ""' do
      should_correct_name 'Hon Member', ''
    end
    it 'should match "Hon Members" to ""' do
      should_correct_name 'Hon Members', ''
    end
    it 'should match "Hon, Members" to ""' do
      should_correct_name 'Hon, Members', ''
    end
    it 'should match "Hon. Hembers" to ""' do
      should_correct_name 'Hon. Hembers', ''
    end
    it 'should match "Hon. Members." to ""' do
      should_correct_name 'Hon. Members.', ''
    end
    it 'should match "Hon. Membes" to ""' do
      should_correct_name 'Hon. Membes', ''
    end
    it 'should match "Hon. Memhers" to ""' do
      should_correct_name 'Hon. Memhers', ''
    end
    it 'should match "Hon., Members" to ""' do
      should_correct_name 'Hon., Members', ''
    end
    it 'should match "Hon.Members" to ""' do
      should_correct_name 'Hon.Members', ''
    end
    it 'should match "Horn. Members" to ""' do
      should_correct_name 'Horn. Members', ''
    end

    describe 'when honorific is LORD' do
      it 'should correct "L ORD "' do
        should_correct_name 'L ORD HAWKE', 'LORD HAWKE'
      end
      it 'should correct "LARD "' do
        should_correct_name 'LARD BURDEN', 'LORD BURDEN'
      end
      it 'should correct "LCRD "' do
        should_correct_name 'LCRD SHEPHERD', 'LORD SHEPHERD'
      end
      it 'should correct "LOAD "' do
        should_correct_name 'LOAD CARSON', 'LORD CARSON'
      end
      it 'should correct "LOAN "' do
        should_correct_name 'LOAN EBURY', 'LORD EBURY'
      end
      it 'should correct "LOBD "' do
        should_correct_name 'LOBD ARNOLD', 'LORD ARNOLD'
      end
      it 'should correct "LOED "' do
        should_correct_name 'LOED BEAVERBROOK', 'LORD BEAVERBROOK'
      end
      it 'should correct "LOHD "' do
        should_correct_name 'LOHD STONEHAVEN', 'LORD STONEHAVEN'
      end
      it 'should correct "LOKD "' do
        should_correct_name 'LOKD BANBURY OF SOUTHAM', 'LORD BANBURY OF SOUTHAM'
      end
      it 'should correct "LOLD "' do
        should_correct_name 'LOLD WINSTER', 'LORD WINSTER'
      end
      it 'should correct "LORB "' do
        should_correct_name 'LORB BURGHCLERE', 'LORD BURGHCLERE'
      end
      it 'should correct "LORD,  "' do
        should_correct_name 'LORD, CHESHAM', 'LORD CHESHAM'
      end
      it 'should correct "LORD. "' do
        should_correct_name 'LORD. ADDISON', 'LORD ADDISON'
      end
      it 'should correct "LORD.[A-Z]"' do
        should_correct_name 'LORD.ARCHIBALD', 'LORD ARCHIBALD'
      end
      it 'should correct "LORD[A-Z]"' do
        should_correct_name 'LORDALNESS', 'LORD ALNESS'
      end
      it 'should correct "LORE "' do
        should_correct_name 'LORE LATHAM', 'LORD LATHAM'
      end
      it 'should correct "LORI) "' do
        should_correct_name 'LORI) BESWICK', 'LORD BESWICK'
      end
      it 'should correct "LORN "' do
        should_correct_name 'LORN WOOLTON', 'LORD WOOLTON'
      end
      it 'should correct "LORO "' do
        should_correct_name 'LORO AMULREE', 'LORD AMULREE'
      end
      it 'should correct "LOUD "' do
        should_correct_name 'LOUD DESBOROUGH', 'LORD DESBOROUGH'
      end
      it 'should correct "LRD "' do
        should_correct_name 'LRD OGMORE', 'LORD OGMORE'
      end
      it 'should correct "LORI "' do
        should_correct_name 'LORI CAWLEY', 'LORD CAWLEY'
      end
      it 'should correct "LORI)[A-Z]"' do
        should_correct_name 'LORI)WINTERBOTTOM', 'LORD WINTERBOTTOM'
      end
      it 'should correct "LORID "' do
        should_correct_name 'LORID CHAMPION', 'LORD CHAMPION'
      end


      describe 'when name is capitalized' do
        it 'should correct "Lard"' do
          should_correct_name 'Lard AVEBURY', 'LORD AVEBURY'
        end
        it 'should correct "Logo"' do
          should_correct_name "Logo HAWKE", "LORD HAWKE"
        end
        it 'should correct "Lora"' do
          should_correct_name "Lora WILMOT OF SELMESTON", "LORD WILMOT OF SELMESTON"
        end
        it 'should correct "Low"' do
          should_correct_name "Low SHACKLETON", "Low SHACKLETON"
        end
        it 'should correct "Loge"' do
          should_correct_name "Loge AIREDALE", "LORD AIREDALE"
        end
        it 'should correct "Loin)"' do
          should_correct_name "Loin) STONHAM", "LORD STONHAM"
        end
        it 'should correct "Long"' do
          should_correct_name "Long DONALDSON OF KINGS-BRIDGE", "LORD DONALDSON OF KINGS-BRIDGE"
        end
        it 'should correct "Loon"' do
          should_correct_name "Loon GARDINER", "LORD GARDINER"
        end
        it 'should correct "Lotto"' do
          should_correct_name "Lotto AVEBURY", "LORD AVEBURY"
        end
        it 'should correct "Lotus"' do
          should_correct_name "Lotus TREVELYAN", "LORD TREVELYAN"
        end
        it 'should correct "Low-)"' do
          should_correct_name "Low-) HAWKE", "LORD HAWKE"
        end
        it 'should correct "Lox!)"' do
          should_correct_name "Lox!) GARDINER", "LORD GARDINER"
        end
        it 'should correct "Lofty"' do
          should_correct_name "Lofty WYNNE-JONES", "LORD WYNNE-JONES"
        end
        it 'should correct "Lords"' do
          should_correct_name "Lords SANDYS", "LORD SANDYS"
        end
        it 'should correct "Loan "' do
          should_correct_name "Loan LUCAS", "LORD LUCAS"
        end
        it 'should correct "Loan" to "Lord"' do
          should_correct_name 'Loan ASKWITH', 'LORD ASKWITH'
        end
        it 'should correct "Lose "' do
          should_correct_name 'Lose KINNAIRD', 'LORD KINNAIRD'
        end
        it 'should correct "Loud "' do
          should_correct_name 'Loud CARSON', 'LORD CARSON'
        end
        it 'should correct "Loup "' do
          should_correct_name 'Loup BLEDISLOE', 'LORD BLEDISLOE'
        end
        it 'should correct "Login "' do
          should_correct_name 'Login GORELL', 'LORD GORELL'
        end
        it 'should correct "Loin "' do
          should_correct_name 'Loin ASHBY ST. LEDGERS', 'LORD ASHBY ST LEDGERS'
        end
        it 'should correct "Lon "' do
          should_correct_name 'Lon STUART OF WORTLEY', 'LORD STUART OF WORTLEY'
        end
        it 'should correct "Loran "' do
          should_correct_name 'Loran GORELL', 'LORD GORELL'
        end
        it 'should correct "Loma "' do
          should_correct_name 'Loma HYLTON', 'LORD HYLTON'
        end
      end
    end

    it 'should correct "Lord." to "Lord"' do
      should_correct_name 'Lord. McIntosh of Haringey', 'Lord McIntosh of Haringey'
    end

    it 'should match " ST " to " ST. "' do
      should_correct_name 'LORD ST OSWALD', 'LORD ST OSWALD'
    end
    it 'should match "ST.OSWALD" to "ST OSWALD"' do
      should_correct_name 'ST.OSWALD', 'ST OSWALD'
    end

    it 'should match "Lieut-Colonel" to "Lieut.-Colonel"' do
      should_correct_name "Lieut-Colonel COLVILLE", "Lieut.-Colonel COLVILLE"
    end
    it 'should match "Lieut. - Colonel" to "Lieut.-Colonel"' do
      should_correct_name "Lieut. - Colonel COLVILLE", "Lieut.-Colonel COLVILLE"
    end
    it 'should match "Lieut. Colonel" to "Lieut.-Colonel"' do
      should_correct_name "Lieut. Colonel COLVILLE", "Lieut.-Colonel COLVILLE"
    end
    it 'should match "Lieut. -Colonel" to "Lieut.-Colonel"' do
      should_correct_name "Lieut. -Colonel COLVILLE", "Lieut.-Colonel COLVILLE"
    end
    it 'should match "Lieut.- Colonel" to "Lieut.-Colonel"' do
      should_correct_name "Lieut.- Colonel COLVILLE", "Lieut.-Colonel COLVILLE"
    end
    it 'should match "Lt.-Col." to "Lieut.-Colonel"' do
      should_correct_name "Lt.-Col. Colin Mitchell", "Lieut.-Colonel Colin Mitchell"
    end
    it 'should match "Lieut.-Colcnel" to "Lieut.-Colonel"' do
      should_correct_name "Lieut.-Colcnel ACLAND-TROYTE", "Lieut.-Colonel ACLAND-TROYTE"
    end

    it 'should match "An Hon Member" to ""' do
      should_correct_name "An Hon Member", ""
    end
    it 'should match "An. Hon. Member" to ""' do
      should_correct_name "An. Hon. Member", ""
    end
    it 'should match "An lion. Member" to ""' do
      should_correct_name "An lion. Member", ""
    end
    it 'should match "Air-Commodore" to "Air Commodore"' do
      should_correct_name "Air-Commodore Harvey", "Air Commodore Harvey"
    end
    it 'should match "Baroness; " to "Baroness "' do
      should_correct_name "Baroness; Mallalieu", "Baroness Mallalieu"
    end

    it 'should match "Rear Admiral" to "Rear-Admiral"' do
      should_correct_name "Rear Admiral Morgan Giles", "Rear-Admiral Morgan Giles"
    end
    it 'should match "Read-Admiral" to "Rear-Admiral"' do
      should_correct_name "Read-Admiral SUETER", "Rear-Admiral SUETER"
    end

    it 'should match "Rev " to "Reverend "' do
      should_correct_name "Rev Ian Paisley", "Reverend Ian Paisley"
    end
    it 'should match "Rev, " to "Reverend "' do
      should_correct_name "Rev, Ian Paisley", "Reverend Ian Paisley"
    end
    it 'should match "Rev., " to "Reverend "' do
      should_correct_name "Rev., Ian Paisley", "Reverend Ian Paisley"
    end
    it 'should match "Rev.[A-Z]" to "Reverend [A-Z]"' do
      should_correct_name "Rev.Martin Smyth", "Reverend Martin Smyth"
    end
    it 'should match "Reverend " to "Reverend "' do
      should_correct_name "Reverend Ian Paisley", "Reverend Ian Paisley"
    end
    it 'should match "Wing-Commander" to "Wing Commander"' do
      should_correct_name "Wing-Commander Bullus", "Wing Commander Bullus"
    end

    it 'should match "Viscount, " to "Viscount "' do
      should_correct_name "Viscount, ALEXANDER OF HILLSBOROUGH", "Viscount ALEXANDER OF HILLSBOROUGH"
    end
    it 'should match "Viscount. " to "Viscount "' do
      should_correct_name "Viscount. ALEXANDER OF HILLSBOROUGH", "Viscount ALEXANDER OF HILLSBOROUGH"
    end
    it 'should match "Viscourrr " to "Viscount "' do
      should_correct_name "Viscourrr ALEXANDER OF HILLS-BOROUGH", "Viscount ALEXANDER OF HILLS-BOROUGH"
    end
    it 'should match "Viscout " to "Viscount "' do
      should_correct_name "Viscout Dilhorne", "Viscount Dilhorne"
    end

    it 'should match "Visount " to "Viscount "' do
      should_correct_name "Visount Davidson", "Viscount Davidson"
    end

    it 'should match "VISCOUNT" to "VISCOUNT"' do
      should_correct_name 'VISCOUNT PEEL', 'VISCOUNT PEEL'
    end
    it 'should match "VISCOUNI" to "VISCOUNT"' do
      should_correct_name 'VISCOUNI SAMUEL', 'VISCOUNT SAMUEL'
    end
    it 'should match "VIS-COUNT" to "VISCOUNT"' do
      should_correct_name 'VIS-COUNT KILMUIR', 'VISCOUNT KILMUIR'
    end
    it 'should match "VISCOTTM" to "VISCOUNT"' do
      should_correct_name 'VISCOTTM ALEXANDER OF HILLSBOROUGH', 'VISCOUNT ALEXANDER OF HILLSBOROUGH'
    end
    it 'should match "VLSCOUNT" to "VISCOUNT"' do
      should_correct_name 'VLSCOUNT CHERWELL', 'VISCOUNT CHERWELL'
    end

    it 'should match "V1SCOLTNT" to "VISCOUNT"' do
      should_correct_name 'V1SCOLTNT PEEL', 'VISCOUNT PEEL'
    end
    it 'should match "VICOUNT" to "VISCOUNT"' do
      should_correct_name 'VICOUNT GALWAY', 'VISCOUNT GALWAY'
    end
    it 'should match "VIKCOUNT" to "VISCOUNT"' do
      should_correct_name 'VIKCOUNT GREY OF FALLODON', 'VISCOUNT GREY OF FALLODON'
    end
    it 'should match "VISCIOUNT" to "VISCOUNT"' do
      should_correct_name 'VISCIOUNT PEEL', 'VISCOUNT PEEL'
    end
    it 'should match "VISCOCNT" to "VISCOUNT"' do
      should_correct_name 'VISCOCNT GALWAY', 'VISCOUNT GALWAY'
    end
    it 'should match "VISCOLUNT" to "VISCOUNT"' do
      should_correct_name 'VISCOLUNT HALDANE', 'VISCOUNT HALDANE'
    end
    it 'should match "VISCONT" to "VISCOUNT"' do
      should_correct_name 'VISCONT HALDANE', 'VISCOUNT HALDANE'
    end
    it 'should match "VISCOTNT" to "VISCOUNT"' do
      should_correct_name 'VISCOTNT PEEL', 'VISCOUNT PEEL'
    end
    it 'should match "VISCOUN" to "VISCOUNT"' do
      should_correct_name 'VISCOUN HALDANE', 'VISCOUNT HALDANE'
    end
    it 'should match "VISCOUNR" to "VISCOUNT"' do
      should_correct_name 'VISCOUNR HALDANE', 'VISCOUNT HALDANE'
    end
    it 'should match "VISCOUNTNT" to "VISCOUNT"' do
      should_correct_name 'VISCOUNTNT HALDANE', 'VISCOUNT HALDANE'
    end
    it 'should match "VISCOUOT" to "VISCOUNT"' do
      should_correct_name 'VISCOUOT PEEL', 'VISCOUNT PEEL'
    end
    it 'should match "VISCOUST" to "VISCOUNT"' do
      should_correct_name 'VISCOUST MIDLETON', 'VISCOUNT MIDLETON'
    end
    it 'should match "VISCOUT" to "VISCOUNT"' do
      should_correct_name 'VISCOUT MORLEY', 'VISCOUNT MORLEY'
    end
    it 'should match "VISCOUTN" to "VISCOUNT"' do
      should_correct_name 'VISCOUTN HALDANE', 'VISCOUNT HALDANE'
    end
    it 'should match "VISCOUUNT" to "VISCOUNT"' do
      should_correct_name 'VISCOUUNT CECIL OF CHELWOOD', 'VISCOUNT CECIL OF CHELWOOD'
    end
    it 'should match "VISCOUXT" to "VISCOUNT"' do
      should_correct_name 'VISCOUXT GREY OF FALLODON', 'VISCOUNT GREY OF FALLODON'
    end
    it 'should match "VISCUNT" to "VISCOUNT"' do
      should_correct_name 'VISCUNT HALDANE', 'VISCOUNT HALDANE'
    end
    it 'should match "VISCOUNTST" to "VISCOUNT"' do
      should_correct_name 'VISCOUNTST ALDWYN', 'VISCOUNT ST ALDWYN'
    end
    it 'should match "VISCUONT" to "VISCOUNT"' do
      should_correct_name 'VISCUONT ST. ALDWYN', 'VISCOUNT ST ALDWYN'
    end
    it 'should match "VISOUNT" to "VISCOUNT"' do
      should_correct_name 'VISOUNT MORLEY', 'VISCOUNT MORLEY'
    end
    it 'should match "VTSCOUNT" to "VISCOUNT"' do
      should_correct_name 'VTSCOUNT CHAPLIN', 'VISCOUNT CHAPLIN'
    end
    it 'should match "DISCOUNT" to "VISCOUNT"' do
      should_correct_name 'DISCOUNT CECIL OF CHELWOOD', 'VISCOUNT CECIL OF CHELWOOD'
    end

    it 'should match "The SOLICITOR - GENERAL" to "The SOLICITOR-GENERAL"' do
      should_correct_name "The SOLICITOR - GENERAL", "The SOLICITOR-GENERAL"
    end

    it 'should match "Name - Name" to "Name-Name"' do
      should_correct_name "Lieut.-Colonel ACLAND - TROYTE", "Lieut.-Colonel ACLAND-TROYTE"
    end
    it 'should match "Name- Name" to "Name-Name"' do
      should_correct_name "Lieut.-Colonel ACLAND- TROYTE", "Lieut.-Colonel ACLAND-TROYTE"
    end
    it 'should match "Name -Name" to "Name-Name"' do
      should_correct_name "Lieut.-Colonel ACLAND -TROYTE", "Lieut.-Colonel ACLAND-TROYTE"
    end

    it 'should match "Major-Gerteral" to "Major-General"' do
      should_correct_name "Major-Gerteral Sir ALFRED KNOX", "Major-General Sir ALFRED KNOX"
    end
    it 'should match "Sir. " to "Sir "' do
      should_correct_name "Sir. G. Nabarro", "Sir G. Nabarro"
    end

    it 'should match two occurances of zero in name each to "O"' do
      zero = 0
      should_correct_name "Mr. CH#{zero}RLT#{zero}N", "Mr CHORLTON"
    end

    it 'should match single occurance of one in name each to "I" when name in caps' do
      should_correct_name "LORD LAM1NGTON", "LORD LAMINGTON"
    end

    it 'should match two occurances of one in name each to "I" when name in caps' do
      one = 1
      should_correct_name "LORD DEN#{one}V#{one}AN", "LORD DENIVIAN"
    end

    it 'should match double zero in name to "OO"' do
      zero = 0
      should_correct_name "Captain CR#{zero}#{zero}KSHANK", "Captain CROOKSHANK"
    end

    it 'should match "Dr " to "Dr "' do
      should_correct_name "Dr BURGIN", "Dr BURGIN"
    end

    it 'should match "(Mr, " to "(Mr "' do
      should_correct_name "(Mr, Frederick Lee)", "Mr Frederick Lee"
    end

    it 'should recognize a name is incorrect if it is surrounded in () characters' do
      should_correct_name "(Viscount Ullswater)", "Viscount Ullswater"
    end

    it 'should correct names with a trailing brace' do
      should_correct_name "VISCOUNT ASTOR}", "VISCOUNT ASTOR"
    end

    it 'should strip a "(for someone else)" suffix from a name' do
      should_correct_name "MR. W. H. SMITH (for Lord ALGERNON PERCY)", "MR W.H. SMITH"
    end

    it 'should correct a name with question numbers and an "asked" suffix' do
      should_correct_name "49.   Mr. De La Bère asked the Chancellor of the Exchequer",  "Mr De La Bère"
    end

    it 'should correct a name with a "said" suffix' do
      should_correct_name "THE MARQUESS OF LONDONDERRY said",  "THE MARQUESS OF LONDONDERRY"
    end

    it 'should correct a name with an "(rising from the Ministerial Front Bench)" suffix' do
      should_correct_name "THE MARQUESS OF LANSDOWNE (rising from the Ministerial Front Bench)",  "THE MARQUESS OF LANSDOWNE"
    end

    it 'should correct a name with question number in the format "6a. Mr. Shinwell"' do
      should_correct_name "6a. Mr. Shinwell",  "Mr Shinwell"
    end

    it 'should correct a name with question number in the format "and 67. Mr. Reynolds"' do
      should_correct_name "and 67. Mr. Reynolds", "Mr Reynolds"
    end

    it 'should correct a name with question number in the format "Q l. Mr. Gray"' do
      should_correct_name "Q l. Mr. Gray", "Mr Gray"
    end

    it 'should correct a name with question number in the format "Q. [98744] Mr. Chris Mullin"' do
      should_correct_name "Q. [98744] Mr. Chris Mullin", "Mr Chris Mullin"
    end

    it 'should correct a name with question number in the format "Q.1 Mr. Churchill"' do
      should_correct_name "Q.1 Mr. Churchill", "Mr Churchill"
    end

    it 'should correct a name with question number in the format "Q.3 Mr. Callaghan"' do
      should_correct_name "Q.3 Mr. Callaghan", "Mr Callaghan"
    end

    it 'should correct a name with question number in the format "Q.4 [94106] Mr. Norman Baker"' do
      should_correct_name "Q.4 [94106] Mr. Norman Baker", "Mr Norman Baker"
    end

    it 'should correct a name with question number in the format "(b) Mr. Malone"' do
      should_correct_name "(b) Mr. Malone", "Mr Malone"
    end

    it 'should correct a name with question number in the format "97.   (P) Mr. Blunkett"' do
      should_correct_name "97.   (P) Mr. Blunkett", "Mr Blunkett"
    end

    it 'should correct a name with question number in the format "92.   (P) Mr. Burns"' do
      should_correct_name "92.   (P) Mr. Burns", "Mr Burns"
    end

    it 'should correct a name with an "asks" suffix' do
      should_correct_name "Mr. Dimbleby asks",  "Mr Dimbleby"
    end

     it 'should correct a name with an "ask" suffix' do
       should_correct_name "Mr. Dobson ask",  "Mr Dobson"
     end

     it 'should not correct a name which ends in ask' do
       should_correct_name "Mr. Dobsonask",  "Mr Dobsonask"
     end

    it 'should strip an "asked..." suffix from a name' do
      should_correct_name "Mr. Cant asked the Chancellor", "Mr Cant"
    end

    it 'should strip a "[holding answer...]" suffix from a name' do
      should_correct_name "Alan Johnson [holding answer 23 February 2004]", "Alan Johnson"
    end

    it 'should strip a "(holding answer...]" suffix from a name' do
      should_correct_name "Jacqui Smith (holding answer 27 November 2002]", "Jacqui Smith"
    end

    it 'should strip a "(who at this juncture re-entered the House)" suffix from a name' do
      should_correct_name "Mr. McNEILL (who at this juncture re-entered the House)", "Mr McNEILL"
    end

    it 'should strip a "(by Private Notice)" suffix from a name' do
      should_correct_name "Captain CUNNINGHAM-REID (by Private Notice)", "Captain CUNNINGHAM-REID"
    end

    it 'should strip a "(seated and covered)" suffix from a name' do
      should_correct_name "Dame Irene Ward(seated and covered)", "Dame Irene Ward"
    end

    it 'should strip a "rose to " suffix from a name' do
      should_correct_name "LORD BEAUMONT OF WHITLEY rose to ask Her Majesty's Government", "LORD BEAUMONT OF WHITLEY"
    end

    it 'should correct "Mr. Rose" to "Mr Rose"' do
      should_correct_name "Mr. Rose", "Mr Rose"
    end

    it 'should strip a "[pursuant to his answer...]" suffix from a name' do
      should_correct_name "Malcolm Wicks [pursuant to his answer, 3 April 2003, Official Report, c. 835–37W]", "Malcolm Wicks"
    end

    it 'should strip a "(in the Clerk\'s place at the Table)" suffix from a name' do
      should_correct_name "Mr. Speaker (in the Clerk's place at the Table)", "Mr Speaker"
    end

    it 'should strip a "(who was indistinctly heard)" suffix from a name' do
      should_correct_name "LORD COLCHESTER (who was indistinctly heard)", "LORD COLCHESTER"
    end

    it 'should strip an "(on behalf of...)" suffix from a name' do
      should_correct_name "LORD NEWTON (on behalf of LORD HAMILTON OF DALZELL)", "LORD NEWTON"
    end

    it 'should strip an "(on behalf of...)" suffix from a name that has a trailing bracket' do
      should_correct_name "THE EARL OF CRAWFORD) (on behalf of the MARQUESS CURZON OF KEDLESTON)", "THE EARL OF CRAWFORD"
    end

    it 'should strip an "indicated assent" suffix from a name' do
      should_correct_name "Mr. Elliot Morley) indicated assent", "Mr Elliot Morley"
    end

    it 'should strip a "[who at this moment...]" suffix from a name' do
      should_correct_name "LORD PARMOOR [who at this moment, entered", "LORD PARMOOR"
    end

    it 'should strip a "(after consulting...)" suffix from a name' do
      should_correct_name "MR. GLADSTONE (after consulting The CHANCELLOR of the EXCHEQUER)", "MR GLADSTONE"
    end

    it 'should strip a "The Chancellor of the Exchequer (Mr. Anthony Barber) (at the bar)" suffix from a name' do
      should_correct_name "The Chancellor of the Exchequer (Mr. Anthony Barber) (at the bar)", "The Chancellor of the Exchequer (Mr Anthony Barber)"
    end

    it 'should strip an "(Urgent Question)" suffix from a name' do
      should_correct_name "Mr. Iain Duncan Smith(Urgent Question)", "Mr Iain Duncan Smith"
    end

    it 'should strip an unspaced "[holding answer ...]" suffix from a name' do
      should_correct_name "Miss Melanie Johnson[holding answer 21 October 2003]", "Miss Melanie Johnson"
    end

    it 'should strip an " moved" suffix from a name' do
      should_correct_name "LORD STONHAM moved", "LORD STONHAM"
    end

    it 'should strip an " rose" suffix from a name' do
      should_correct_name "LORD STRABOLGI rose", "LORD STRABOLGI"
    end

    it 'should strip an " rose&#x2014;" suffix from a name' do
      should_correct_name "Dr. Lynne Jones rose&#x2014;", "Dr Lynne Jones"
    end

    it 'should strip an "(standing in his place)" suffix from a name' do
      should_correct_name "Mr. Selwyn Lloyd(standing in his place)", "Mr Selwyn Lloyd"
    end

    it 'should strip an " rose to move[...]" suffix from a name' do
      should_correct_name "THE SECRETARY OF STATE FOR DEFENCE (LORD CARRINGTON) rose to move, That this House takes note", "THE SECRETARY OF STATE FOR DEFENCE (LORD CARRINGTON)"
    end

    it 'should strip a "THE EARL OF AIRLIE moved, in subsection (4), " to "THE EARL OF AIRLIE"' do
      should_correct_name "THE EARL OF AIRLIE moved, in subsection (4),", "THE EARL OF AIRLIE"
    end

    it 'should strip an "(on behalf of ...)" suffix from a name' do
      should_correct_name "Mr. Paul Channon (on behalf of the Finance and Services Committee)", "Mr Paul Channon"
    end

    it 'should strip empty trailing brackets' do
      should_correct_name "Dr. Alan Glyn ()", "Dr Alan Glyn"
    end

    it 'should correct "THE LORD PRTVY SEAL" to "THE LORD PRIVY SEAL"' do
      should_correct_name "THE LORD PRTVY SEAL AND SECRETARY OF STATE FOR THE COLONIES", "THE LORD PRIVY SEAL AND SECRETARY OF STATE FOR THE COLONIES"
    end

    it 'should correct "THE LORD PRIVY REAL" to "THE LORD PRIVY SEAL"' do
      should_correct_name "THE LORD PRIVY REAL AND SECRETARY OF STATE FOR INDIA", "THE LORD PRIVY SEAL AND SECRETARY OF STATE FOR INDIA"
    end

    it 'should correct "TEE LORD CHANCELLOR" to "THE LORD CHANCELLOR"' do
      should_correct_name "TEE LORD CHANCELLOR", "THE LORD CHANCELLOR"
    end

    it 'should correct "TEE LORD CHANCELLOR (VISCOUNT SANKEY)" to "THE LORD CHANCELLOR (VISCOUNT SANKEY)"' do
      should_correct_name "TEE LORD CHANCELLOR (VISCOUNT SANKEY)", "THE LORD CHANCELLOR (VISCOUNT SANKEY)"
    end

    it 'should correct "TEH LORD CHANCELLOR (VISCOUNT JOWITT)" to "THE LORD CHANCELLOR (VISCOUNT JOWITT)"' do
      should_correct_name "TEH LORD CHANCELLOR (VISCOUNT JOWITT)", "THE LORD CHANCELLOR (VISCOUNT JOWITT)"
    end

    it 'should correct "TETE LORD CHANCELLOR" to "THE LORD CHANCELLOR"' do
      should_correct_name "TETE LORD CHANCELLOR", "THE LORD CHANCELLOR"
    end

    it 'should correct "THE, LORD CHANCELLOR" to "THE LORD CHANCELLOR"' do
      should_correct_name "THE, LORD CHANCELLOR", "THE LORD CHANCELLOR"
    end

    it 'should correct "THE SECRETARY OF STATE FOR WAR (VISCOUNT HAILSHAM)" to "THE SECRETARY OF STATE FOR WAR (VISCOUNT HAILSHAM)"' do
      should_correct_name "THE. SECRETARY OF STATE FOR WAR (VISCOUNT HAILSHAM)", "THE SECRETARY OF STATE FOR WAR (VISCOUNT HAILSHAM)"
    end

    it 'should correct "TEIE MINISTER OF STATE, MINISTRY OF TECHNOLOGY (LORD DELACOURT-SMITH)" to "THE MINISTER OF STATE, MINISTRY OF TECHNOLOGY (LORD DELACOURT-SMITH)"' do
      should_correct_name "TEIE MINISTER OF STATE, MINISTRY OF TECHNOLOGY (LORD DELACOURT-SMITH)", "THE MINISTER OF STATE, MINISTRY OF TECHNOLOGY (LORD DELACOURT-SMITH)"
    end

    it 'should correct "THH DUKE OF DEVONSHIRE" to "THE DUKE OF DEVONSHIRE"' do
      should_correct_name "THH DUKE OF DEVONSHIRE", "THE DUKE OF DEVONSHIRE"
    end

    it 'should correct "THIS UNDER-SECRETARY OF STATE FOR WAR (THE EARL OF ONSLOW)" to "THE UNDER-SECRETARY OF STATE FOR WAR (THE EARL OF ONSLOW)"' do
      should_correct_name "THIS UNDER-SECRETARY OF STATE FOR WAR (THE EARL OF ONSLOW)", "THE UNDER-SECRETARY OF STATE FOR WAR (THE EARL OF ONSLOW)"
    end

    describe 'when honorific in parenthesis' do
      it 'should correct THE MARQUESS honorific' do
        should_correct_name "THE PARLIAMENTARY UNDER-SECRETARY OF STATE FOR FOREIGN AFFAIRS (TEH: MARQUESS OF READING)", "THE PARLIAMENTARY UNDER-SECRETARY OF STATE FOR FOREIGN AFFAIRS (THE MARQUESS OF READING)"
        should_correct_name 'THE LORD PRESIDENT OF THE COUNCIL (THE MARQUERS OF CREWE)', 'THE LORD PRESIDENT OF THE COUNCIL (THE MARQUESS OF CREWE)'
      end

      it 'should correct THE DUKE honorific' do
        should_correct_name 'THE JOINT PARLIAMENTARY SECRETARY OF THE BOARD OF AGRICULTURE (THE DCKE OF MARLBOROUGH)', 'THE JOINT PARLIAMENTARY SECRETARY OF THE BOARD OF AGRICULTURE (THE DUKE OF MARLBOROUGH)'
      end

      it 'should correct THE EARL honorific' do
        should_correct_name 'THE PRESIDENT OF THE BOARD OF AGRICULTURE AND FISHERIES (THE EARL OP SELBORNE)', 'THE PRESIDENT OF THE BOARD OF AGRICULTURE AND FISHERIES (THE EARL OF SELBORNE)'
      end

      it 'should correct VISCOUNT honorific' do
        should_correct_name '*THE LORD CHANCELLOR (VICOUNT HALDANE)', 'THE LORD CHANCELLOR (VISCOUNT HALDANE)'
      end

      it 'should correct EARL honorific' do
        should_correct_name 'THE PRESIDENT OF THE BOARD OF AGRICULTURE AND FISHERIES (EARL. CARRINGTON)', 'THE PRESIDENT OF THE BOARD OF AGRICULTURE AND FISHERIES (EARL CARRINGTON)'
      end

      it 'should correct LORD' do
        should_correct_name 'THE LORD CHANCELLOR (Loan LOREBURN)', 'THE LORD CHANCELLOR (LORD LOREBURN)'
      end
    end

    it 'should correct "THH LORD CHANCELLOR" to "THE LORD CHANCELLOR"' do
      should_correct_name "THH LORD CHANCELLOR", "THE LORD CHANCELLOR"
    end

    it 'should correct "THF LORD CHANCELLOR" to "THE LORD CHANCELLOR"' do
      should_correct_name "THF LORD CHANCELLOR", "THE LORD CHANCELLOR"
    end

    it 'should correct "THE DCKE " to "THE DUKE "' do
      should_correct_name "THE DCKE OF MARLBOROUGH", "THE DUKE OF MARLBOROUGH"
    end
    it 'should correct "THE DUKE. " to "THE DUKE "' do
      should_correct_name "THE DUKE. OF NORTHUMBERLAND", "THE DUKE OF NORTHUMBERLAND"
    end
    it 'should correct "THE LORD \'BISHOP " to "THE LORD BISHOP "' do
      should_correct_name "THE LORD 'BISHOP OF DURHAM", "THE LORD BISHOP OF DURHAM"
    end
    it 'should correct "THE LORD BISHOP or " to "THE LORD BISHOP OF "' do
      should_correct_name "THE LORD BISHOP or ST DAVID'S", "THE LORD BISHOP OF ST DAVID'S"
    end

    describe 'when honorific is THE LORD ARCHBISHOP OF' do
      it 'should correct "THE LORD AREHBISHOP "' do
        should_correct_name "THE LORD AREHBISHOP OF CANTERBURY", "THE LORD ARCHBISHOP OF CANTERBURY"
      end
      it 'should correct "THE LORD ARCHBISHOP or "' do
        should_correct_name "THE LORD ARCHBISHOP or CANTERBURY", "THE LORD ARCHBISHOP OF CANTERBURY"
      end
    end

    describe 'when correct honorific is THE MARQUESS OF' do
      it 'should correct "TRE MARQUESS"' do
        should_correct_name "TRE MARQUESS OF LANSDOWNE", "THE MARQUESS OF LANSDOWNE"
      end
      it 'should correct "THE MARQUESS COT"' do
        should_correct_name 'THE MARQUESS COT LANSDOWNE', 'THE MARQUESS OF LANSDOWNE'
      end
      it 'should correct "THM MARQUESS "' do
        should_correct_name "THM MARQUESS OF CREWE", "THE MARQUESS OF CREWE"
      end
      it 'should correct "*THE MARQUESS or"' do
        should_correct_name "*THE MARQUESS or CREWE", "THE MARQUESS OF CREWE"
      end
      it 'should correct "TIER MARQUESS "' do
        should_correct_name "TIER MARQUESS OF SALISBURY", "THE MARQUESS OF SALISBURY"
      end
      it 'should correct "TIE MARQUESS "' do
        should_correct_name "TIE MARQUESS OF LOTHIAN", "THE MARQUESS OF LOTHIAN"
      end
      it 'should correct "T1IE MARQUESS "' do
        should_correct_name "T1IE MARQUESS OF SALISBURY", "THE MARQUESS OF SALISBURY"
      end
      it 'should correct "THE MARQUESS OF. "' do
        should_correct_name "THE MARQUESS OF. SALISBURY", "THE MARQUESS OF SALISBURY"
      end
      it 'should correct "THE MARQUESSS OF "' do
        should_correct_name "THE MARQUESSS OF CREWE", "THE MARQUESS OF CREWE"
      end
      it 'should correct "THE MARQUESS, OF "' do
        should_correct_name "THE MARQUESS, OF CREWE", "THE MARQUESS OF CREWE"
      end
      it 'should correct "MARQUEES OF"' do
        should_correct_name "MARQUEES OF LANSDOWNE", "MARQUESS OF LANSDOWNE"
      end
    end

    it 'should correct "THE DUKE OK " to "THE DUKE OF "' do
      should_correct_name "THE DUKE OK ARGYLL", "THE DUKE OF ARGYLL"
    end
    it 'should correct "THE DUKE OP " to "THE DUKE OF "' do
      should_correct_name "THE DUKE OP ATHOLL", "THE DUKE OF ATHOLL"
    end
    it 'should correct "THE DUKE op " to "THE DUKE OF "' do
      should_correct_name "THE DUKE op DEVONSHIRE", "THE DUKE OF DEVONSHIRE"
    end
    it 'should correct "THE DUKE,OF " to "THE DUKE OF "' do
      should_correct_name "THE DUKE,OF NORFOLK", "THE DUKE OF NORFOLK"
    end
    it 'should correct "THE DUKK OF " to "THE DUKE OF "' do
      should_correct_name "THE DUKK OF DEVONSHIRE", "THE DUKE OF DEVONSHIRE"
    end


    describe 'when correct honorific is BARONESS' do
      it 'should correct BARONESSS' do
        should_correct_name 'BARONESSS SWANBOROUGH', 'BARONESS SWANBOROUGH'
      end
      it 'should correct BAROYESS' do
        should_correct_name 'BAROYESS WOOTTON OF ABINGER', 'BARONESS WOOTTON OF ABINGER'
      end
      it 'should correct BARONESS XXX or' do
        should_correct_name 'BARONESS BURTON or COVENTRY', 'BARONESS BURTON OF COVENTRY'
      end
      it 'should correct BARONESS XXX or' do
        should_correct_name 'BARONESS BURTON or COVENTRY', 'BARONESS BURTON OF COVENTRY'
      end
      it 'should correct BAP. ONESS' do
        should_correct_name 'BAP. ONESS WHITE', 'BARONESS WHITE'
      end
    end

    it 'should correct "TIIE MINISTER OF STATE, SCOT-TISH OFFICE (BARONESS TWEEDSMUIR OF BELHELVIE)" to "TIIE MINISTER OF STATE, SCOT-TISH OFFICE (BARONESS TWEEDSMUIR OF BELHELVIE)"' do
      should_correct_name "TIIE MINISTER OF STATE, SCOT-TISH OFFICE (BARONESS TWEEDSMUIR OF BELHELVIE)", "TIIE MINISTER OF STATE, SCOT-TISH OFFICE (BARONESS TWEEDSMUIR OF BELHELVIE)"
    end

    it 'should correct "TILE MINISTER OF STATE, DEPARTMENT OF ENERGY (LORD BALOGH)" to "TILE MINISTER OF STATE, DEPARTMENT OF ENERGY (LORD BALOGH)"' do
      should_correct_name "TILE MINISTER OF STATE, DEPARTMENT OF ENERGY (LORD BALOGH)", "TILE MINISTER OF STATE, DEPARTMENT OF ENERGY (LORD BALOGH)"
    end

    it 'should correct "Madam. Deputy Speaker (Mrs. " to "Madam Deputy Speaker (Mrs "' do
      should_correct_name "Madam. Deputy Speaker (Mrs. Sylvia Heal)", "Madam Deputy Speaker (Mrs Sylvia Heal)"
    end

    it 'should correct "Madam. Deputy Speaker" to "Madam Deputy Speaker"' do
      should_correct_name "Madam. Deputy Speaker", "Madam Deputy Speaker"
    end

    it 'should correct "Madam, Speaker" to "Madam Speaker"' do
      should_correct_name "Madam, Speaker", "Madam Speaker"
    end

    it 'should correct "Madam. Speaker" to "Madam Speaker"' do
      should_correct_name "Madam. Speaker", "Madam Speaker"
    end

    it 'should correct "Madam: Deputy Speaker (Dame Janet Fookes)" to "Madam Deputy Speaker (Dame Janet Fookes)"' do
      should_correct_name "Madam: Deputy Speaker (Dame Janet Fookes)", "Madam Deputy Speaker (Dame Janet Fookes)"
    end

    it 'should correct "Madame Deputy Speaker" to "Madam Deputy Speaker"' do
      should_correct_name "Madame Deputy Speaker", "Madam Deputy Speaker"
    end

    it 'should correct "Madem Speaker" to "Madam Speaker"' do
      should_correct_name "Madem Speaker", "Madam Speaker"
    end

    it 'should correct "THE LORD CHANCELLOR (LORD MAUGHAM)" to "THE LORD CHANCELLOR (LORD, MAUGHAM)"' do
      should_correct_name "THE LORD CHANCELLOR (LORD, MAUGHAM)", "THE LORD CHANCELLOR (LORD MAUGHAM)"
    end

    it 'should correct "THE LORD CHANCELLOR (LORD) SANKEY)" to "THE LORD CHANCELLOR (LORD SANKEY)"' do
      should_correct_name "THE LORD CHANCELLOR (LORD) SANKEY)", "THE LORD CHANCELLOR (LORD SANKEY)"
    end

    it 'should correct "THE: LORD CHANCELLOR" to "THE LORD CHANCELLOR"' do
      should_correct_name "THE: LORD CHANCELLOR", "THE LORD CHANCELLOR"
    end

    it 'should correct "A MINISTERIAL PEER" to ""' do
      should_correct_name "A MINISTERIAL PEER", ""
    end

    it 'should correct "MY LORDS, AND MEMBERS OF THE HOUSE OF COMMONS." to ""' do
      should_correct_name "MY LORDS, AND MEMBERS OF THE HOUSE OF COMMONS.", ""
    end

    it 'should correct "My Lords and Members of the House of Commons" to ""' do
      should_correct_name "My Lords and Members of the House of Commons", ""
    end

    it 'should correct "Members of the House of Commons" to ""' do
      should_correct_name "Members of the House of Commons", ""
    end

    it 'should correct "Hon. Members: Object" to ""' do
      should_correct_name "Hon. Members: Object", ""
    end

    it 'should correct "My hon. Friend" to ""' do
      should_correct_name "My hon. Friend", ""
    end

    it 'should correct "The hon. Member for North Wiltshire (Mr. Gray)" to ""' do
      should_correct_name "The hon. Member for North Wiltshire (Mr. Gray)", ""
    end

    it 'should correct "My hon. Friend (Mr. Hannan)" to ""' do
      should_correct_name "My hon. Friend (Mr. Hannan)", ""
    end

    it 'should correct "lion. Members" to ""' do
      should_correct_name "lion. Members", ""
    end

    it 'should correct "A noble Baroness" to ""' do
      should_correct_name "A noble Baroness", ""
    end

    it 'should correct "A NOME LORD" to ""' do
      should_correct_name "A NOME LORD", ""
    end

    it 'should correct "A NOELS LORD" to ""' do
      should_correct_name "A NOELS LORD", ""
    end

    it 'should correct "Other Hon. Members" to ""' do
      should_correct_name "Other Hon. Members", ""
    end

    it 'should correct "Sereval Hon. Members" to ""' do
      should_correct_name "Sereval Hon. Members", ""
    end

    it 'should correct "Several Hon. Member" to ""' do
      should_correct_name "Several Hon. Member", ""
    end

    it 'should correct "Several Hon" to ""' do
      should_correct_name "Several Hon", ""
    end

    it 'should correct "Several Hen. Members " to ""' do
      should_correct_name "Several Hen. Members ", ""
    end

    it 'should correct "Several Don. Members" to ""' do
      should_correct_name "Several Don. Members", ""
    end

    it 'should correct "Several 114m. Members rose" to ""' do
      should_correct_name "Several 114m. Members rose", ""
    end

    it 'should correct "Sevaral Hon. Members" to ""' do
      should_correct_name "Sevaral Hon. Members", ""
    end

    it 'should correct "Several Hon Members" to ""' do
      should_correct_name "Several Hon Members", ""
    end

    it 'should correct "Several Hon, Members" to ""' do
      should_correct_name "Several Hon, Members", ""
    end

    it 'should correct "Several Hon. Members" to ""' do
      should_correct_name "Several Hon. Members", ""
    end

    it 'should correct "Several Hon. Members" to ""' do
      should_correct_name "Several Hon. Members", ""
    end

    it 'should correct "Several Hon. Members rose—" to ""' do
      should_correct_name "Several Hon. Members rose—", ""
    end

    it 'should correct "Several Hon. Membrs" to ""' do
      should_correct_name "Several Hon. Membrs", ""
    end

    it 'should correct "Several Lords" to ""' do
      should_correct_name "Several Lords", ""
    end

    it 'should correct "Several NOBLE LORD" to ""' do
      should_correct_name "Several NOBLE LORD", ""
    end

    it 'should correct "Several NOBLE Loans" to ""' do
      should_correct_name "Several NOBLE Loans", ""
    end

    it 'should correct "Several hon. Members rose" to ""' do
      should_correct_name "Several hon. Members rose", ""
    end

    it 'should correct "Several hon.Members" to ""' do
      should_correct_name "Several hon.Members", ""
    end

    it 'should correct "Several lion. Members" to ""' do
      should_correct_name "Several lion. Members", ""
    end

    it 'should correct "Several-hon. Members" to ""' do
      should_correct_name "Several-hon. Members", ""
    end

    it 'should correct "Several. Hon. Members" to ""' do
      should_correct_name "Several. Hon. Members", ""
    end

    it 'should correct "Several/ Hon. Members" to ""' do
      should_correct_name "Several/ Hon. Members", ""
    end

    it 'should correct "Severaln Hon. Members" to ""' do
      should_correct_name "Severaln Hon. Members", ""
    end

    it 'should correct "Sereval Hon. Members" to ""' do
      should_correct_name "Sereval Hon. Members", ""
    end

    it 'should correct "A Nationalist Member" to ""' do
      should_correct_name "A Nationalist Member", ""
    end

    it 'should correct "Several noble Lords" to ""' do
      should_correct_name "Several noble Lords", ""
    end

    it 'should correct "Noble Lords" to ""' do
      should_correct_name "Noble Lords", ""
    end

    it 'should correct "My hon. Friend the Member for Exeter (Mr. Hannan)" to ""' do
      should_correct_name "My hon. Friend the Member for Exeter (Mr. Hannan)", ""
    end

    it 'should correct a name of more than 20 words with a colon in it to the text before the colon' do
      should_correct_name "Lord Strathclyde: My Lords, funding is not restricted to national organisations. Any national or local voluntary organisation offering direct, practical help to homeless people has been eligible since 1990 to apply for grant under Section 73 of the Housing Act 1985.", "Lord Strathclyde"
    end

    it 'should correct a name of more than 20 words to an empty string' do
      should_correct_name "Lord Williams of Elvel My Lords, I am grateful to the noble Lord for giving way. What is the origin of the Bill? We have a Bill which is apparently a Private Member's Bill, on which no noble Lord other than the Minister can speak in an official capacity", ""
    end

    it 'should strip any text after a colon' do
      should_correct_name "Baroness Jay of Paddington: My Lords, I agree with my noble friend. I repeat", "Baroness Jay of Paddington"
    end

    it 'should correct "Mr. John Smith (Cities of London and Westminister)" to "Mr John Smith (Cities of London and Westminster)"' do
      should_correct_name "Mr. John Smith (Cities of London and Westminister)", "Mr John Smith (Cities of London and Westminster)"
    end

    it 'should correct "MR.CHANNING" to "MR CHANNING"' do
      should_correct_name "MR.CHANNING", "MR CHANNING"
    end

    it 'should correct "MR SHAW LEFEVEE" to "MR SHAW LEFEVEE"' do
      should_correct_name "MR SHAW LEFEVEE", "MR SHAW LEFEVEE"
    end

    it 'should correct "MR. CAMPBELL&#x2014;BANNERMAN" to "MR CAMPBELL-BANNERMAN"' do
      should_correct_name 'MR. CAMPBELL&#x2014;BANNERMAN', 'MR CAMPBELL-BANNERMAN'
    end

    it 'should correct "Mr. Dale Campbell&#x2013;Savours" to "Mr Dale Campbell-Savours"' do
      should_correct_name "Mr. Dale Campbell&#x2013;Savours", "Mr Dale Campbell-Savours"
    end

    it 'should correct "Tim Loughton" to "Tim Loughton"' do
      should_correct_name "Tim Loughton", "Tim Loughton"
    end

    it 'should correct "MR. T. P. O\'CONNOR" to "MR. T.P. O\'CONNOR"' do
      should_correct_name "MR. T. P. O'CONNOR", "MR T.P. O'CONNOR"
    end

    it 'should correct "MR. A. R. D. ELLIOT" to "MR A.R.D. ELLIOT"' do
      should_correct_name "MR. A. R. D. ELLIOT", "MR A.R.D. ELLIOT"
    end

    it 'should correct "Mr. St. John-Stevas" to "Mr St John-Stevas"' do
      should_correct_name "Mr. St. John-Stevas", "Mr St John-Stevas"
    end

    it 'should correct "SIR CHARLES W, DILKE" to "SIR CHARLES W. DILKE"' do
      should_correct_name "SIR CHARLES W, DILKE", "SIR CHARLES W. DILKE"
    end

    # Baroness Bendel! of Babergh
    #
  end

  describe 'when correcting mis-spelling of "Part"' do

    def should_correct_part text, corrected_text
      self.class.correct_part(text).should == corrected_text
    end

    it 'should correct "Fart II" to "Part II"' do
      should_correct_part 'under Fart II of the Land Drainage Act,', 'under Part II of the Land Drainage Act,'
    end

    it 'should correct "Fart I" to "Part I"' do
      should_correct_part 'Fart I', 'Part I'
    end

    it 'should correct "Fart IV" to "Part IV"' do
      should_correct_part 'Fart IV', 'Part IV'
    end

    it 'should correct "Fart V" to "Part V"' do
      should_correct_part 'Fart V', 'Part V'
    end

    it 'should correct "this Fart" to "this Part"' do
      should_correct_part 'leave out ("this Fart") and insert ("Section six and Section seven") ', 'leave out ("this Part") and insert ("Section six and Section seven") '
    end

    it 'should correct "Fart thereof" to "Part thereof"' do
      should_correct_part 'or any Fart thereof,', 'or any Part thereof,'
    end

  end

  describe 'when correcting mis-spelling of "fact"' do

    def should_correct_fact text, corrected_text
      self.class.correct_fact(text).should == corrected_text
    end

    it 'should correct "a fart of" to "a fact of"' do
      should_correct_fact 'a fart of', 'a fact of'
    end

    it 'should correct "these farts" to "these facts"' do
      should_correct_fact 'these farts', 'these farts'
    end

    it 'should correct "the fart that" to "the fact that"' do
      should_correct_fact 'the fart that', 'the fact that'
    end

    it 'should correct "in fart" to "in fact"' do
      should_correct_fact 'in fart', 'in fact'
    end

    it 'should correct "these farts before" to "these facts before"' do
      should_correct_fact 'these farts before', 'these facts before'
    end

  end
end