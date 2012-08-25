require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1932, 6, 7)
    @sitting_date_text = 'Tuesday, 7th June, 1932.'
    @sitting_title = 'HOUSE OF COMMONS.'
    @sitting_start_column = '1777'
    @sitting_end_column = '1781'
    file = 'housecommons_split_division_table.xml'
    @sitting_chairman = 'Mr. SPEAKER'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, mock_model(SourceFile, :volume => mock_model(Volume), :series_number=>5)

    @sitting.save!

    @first_section = @sitting.debates.sections.first
    @contribution_following_division_start = @first_section.contributions[1]
    @division_placeholder = @first_section.contributions[7]
    @division = @division_placeholder.division
  end

  it_should_behave_like "All sittings"

  it 'should not create division placeholder for division element that occurs prior to the "The House divided" text' do
    @contribution_following_division_start.should_not be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division placeholder contribution for division element with continuation of ayes table' do
    @division_placeholder.should be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division for division element with start of ayes table' do
    @division.should be_an_instance_of(CommonsDivision)
  end

  it 'should create division name' do
    @division.name.should == 'Division No. 214.]'
  end

  it 'should create division time text' do
    @division.time_text.should == '[3.33 p. m.'
  end

  it 'should create division time' do
    @division.time.hour.should == 15 # [3.33 p. m.
    @division.time.min.should == 33
  end

  it 'should create aye vote' do
    @division.votes[0].should_not be_nil
    @division.votes[0].should be_an_instance_of(AyeVote)
  end

  it 'should set aye vote name' do
    @division.votes[0].name.should == 'Acland-Troyte, Lieut.-Colonel'
  end

  it 'should set aye vote column' do
    @division.votes[0].column.should == '1777'
  end

  it 'should set aye vote name and constituency when present' do
    @division.votes[3].name.should == 'Adams, Samuel Vyvyan T.'
    @division.votes[3].constituency.should == "Leeds, W."
  end

  it 'should reuse previously created division for continuation of ayes table' do
    @division_placeholder.division.should == @division
  end

  it 'should create teller aye votes for the cells that appear below the cell containing the heading "Tellers for the Ayes"' do
    @division.aye_teller_votes.size.should == 2
    @division.aye_teller_votes[0].name.should == 'Sir Frederick Thomson'
    @division.aye_teller_votes[1].name.should == 'Lord Erskine'
  end

  it 'should create teller noe votes for the cells that appear below the cell containing the heading "Tellers for the Noes"' do
    @division.noe_teller_votes.size.should == 2

    @division.noe_teller_votes[0].name.should == 'Mr. John'
    @division.noe_teller_votes[1].name.should == 'Mr. Groves'
  end

  it 'should have name correct on last aye vote' do
    @division.aye_votes.last.name.should == 'Ramsay, Capt. A. H. M.'
  end

  it 'should set complete division text on the single placeholder contribution' do
    @division_placeholder.text.should == %Q|<table>
<tr>
<td align="center">
<b>Division No. 214.]</b>
</td>
<td align="center">
<b>AYES.</b>
</td>
<td align="right">
<b>[3.33 p. m.</b>
</td>
</tr>
<tr>
<td>Acland-Troyte, Lieut.-Colonel</td>
<td>Briscoe, Capt. Richard George</td>
<td>Christie, James Archibald</td>
</tr>
<tr>
<td>Adams, Samuel Vyvyan T. (Leeds, W.)</td>
<td>Broadbent, Colonel John</td>
<td>Clayton, Dr. George C.</td>
</tr>
<tr>
<td>Agnew, Lieut.-Com. P. G.</td>
<td>Brockiebank, C. E. R.</td>
<td>Clydesdale, Marquess of</td>
</tr>
<tr>
<td>Aitchison, Rt. Hon. Craigle M.</td>
<td>Brown, Col. D. C. (N'th'l'd, Hexham)</td>
<td>Colman, N. C. D.</td>
</tr>
<tr>
<td>Albery, Irving James</td>
<td>Brown, Ernest (Leith)</td>
<td>Conant, R. J. E.</td>
</tr>
<tr>
<td>Allen, Lt.-Col. J. Sandeman (B'k'nhd.)</td>
<td>Browne, Captain A. C.</td>
<td>Cook, Thomas A.</td>
</tr>
<tr>
<td>Apsley, Lord</td>
<td>Buchan-Hepburn, P. G. T.</td>
<td>Cooke, Douglas</td>
</tr>
<tr>
<td>Astor. Maj. Hn. John J. (Kent, Dover)</td>
<td>Bullock, Captain Malcolm</td>
<td>Cooper, A. Duff</td>
</tr>
<tr>
<td>Atholl, Duchess of</td>
<td>Burghley, Lord</td>
<td>Copeland, Ida</td>
</tr>
<tr>
<td>Baillie, Sir Adrian W. M.</td>
<td>Burnett, John George</td>
<td>Courthope, Colonel Sir George L.</td>
</tr>
<tr>
<td>Baldwin, Rt. Hon. Stanley</td>
<td>Cadogan, Hon. Edward</td>
<td>Craddock, Sir Reginald Henry</td>
</tr>
<tr>
<td>Barton, Capt. Basil Kelsey</td>
<td>Caine, G. R. Hall-</td>
<td>Cranborne, Viscount</td>
</tr>
<tr>
<td>Beaumont, M. W. (Bucks., Aylesbury)</td>
<td>Campbell, Edward Taswell (Bromley)</td>
<td>Craven-Ellis, William</td>
</tr>
<tr>
<td>Beaumont, Hon. R. E. B. (Portsm'th, C)</td>
<td>Caporn, Arthur Cecil</td>
<td>Crooke, J. Smedley</td>
</tr>
<tr>
<td>Belt, Sir Alfred L.</td>
<td>Cautley, Sir Henry S.</td>
<td>Crookshank, Capt. H. C. (Gainsb'ro)</td>
</tr>
<tr>
<td>Betterton, Rt. Hon. Sir Henry B.</td>
<td>Cayzer, Sir Charles (Chester, City)</td>
<td>Cruddas, Lieut.-Colonel Bernard</td>
</tr>
<tr>
<td>Birchall, Major Sir John Dearman</td>
<td>Cayzer, Maj. Sir H. R. (Prtsmth., S.)</td>
<td>Dalkeith, Earl of</td>
</tr>
<tr>
<td>Blaker, Sir Reginald</td>
<td>Cazalet, Thelma (Islington, E.)</td>
<td>Davies, Maj. Geo. F. (Somerset, Yeovil)</td>
</tr>
<tr>
<td>Bossom, A. C.</td>
<td>Chalmers, John Rutherford</td>
<td>Davison, Sir William Henry</td>
</tr>
<tr>
<td>Boulton, W. W.</td>
<td>Chamberlain, Rt. Hon. Sir J. A. (Birm., W)</td>
<td>Denman, Hon. R. D.</td>
</tr>
<tr>
<td>Bowater, Col. Sir T. Vansittart</td>
<td>Chamberlain, Rt. Hn. N. (Edgbaston)</td>
<td>Denville, Alfred</td>
</tr>
<tr>
<td>Sower, Lieut.-Com. Robert Tatton</td>
<td>Chapman, Col. R. (Houghton-le-Spring)</td>
<td>Despencer-Robertson, Major J. A. F.</td>
</tr>
<tr>
<td>Bowyer, Capt. Sir George E. W.</td>
<td>Chorlton, Alan Ernest Leofric</td>
<td>Dickle, John P.</td>
</tr>
<tr>
<td>Braithwaite, J. G. (Hillsborough)</td>
<td>Chotzner, Alfred James</td>
<td>Dixon, Rt. Hon. Herbert</td>
</tr>


<tr>
<td>Donner, P. W.</td>
<td>Knox, Sir Alfred</td>
<td>Ramsay, T. B. W. (Western Isles)</td>
</tr>
<tr>
<td>Dower, Captain A. V. G.</td>
<td>Lamb, Sir Joseph Quinton</td>
<td>Ramsbotham, Herwald</td>
</tr>
<tr>
<td>Drewe, Cedric</td>
<td>Latham, Sir Herbert Paul</td>
<td>Ramsden, E.</td>
</tr>
<tr>
<td>Duggan, Hubert John</td>
<td>Law, Richard K. (Hull, S. W.)</td>
<td>Rankin, Robert</td>
</tr>
<tr>
<td>Duncan, James A. L. (Kensington, N.)</td>
<td>Leech, Dr. J. W.</td>
<td>Rathbone, Eleanor</td>
</tr>
<tr>
<td>Dunglass, Lord</td>
<td>Lees-Jones, John</td>
<td>Rawson, Sir Cooper</td>
</tr>
<tr>
<td>Eady, George H.</td>
<td>Levy, Thomas</td>
<td>Rea, Walter Russell</td>
</tr>
<tr>
<td>Eden, Robert Anthony</td>
<td>Lewis, Oswald</td>
<td>Reed, Arthur C. (Exeter)</td>
</tr>
<tr>
<td>Ednam, Viscount</td>
<td>Liddall, Walter S.</td>
<td>Reid, Capt. A. Cunningham-</td>
</tr>
<tr>
<td>Elliot, Major Rt. Hon. Walter, E.</td>
<td>Lindsay, Noel Ker</td>
<td>Reid, James S. C. (Stirling)</td>
</tr>
<tr>
<td>Elliston, Captain George Sampson</td>
<td>Llewellyn-Jones, Frederick</td>
<td>Reid, William Allan (Derby)</td>
</tr>
<tr>
<td>Elmley, Viscount</td>
<td>Lloyd, Geoffrey</td>
<td>Remer, John R.</td>
</tr>
<tr>
<td>Emmott, Charles E. G. C.</td>
<td>Locker-Lampson, Rt. Hn. G. (Wd. Gr'n)</td>
<td>Rhys, Hon. Charles Arthur U.</td>
</tr>
<tr>
<td>Emrys-Evans, P. V.</td>
<td>Loder, Captain J. de Vere</td>
<td>Robinson, John Roland</td>
</tr>
<tr>
<td>Erskine-Bolst, Capt. C. C. (Blackpool)</td>
<td>Lovat-Fraser, James Alexander</td>
<td>Rosbotham, S. T.</td>
</tr>
<tr>
<td>Everard, W. Lindsay</td>
<td>Lumley, Captain Lawrence R.</td>
<td>Ross Taylor, Walter (Woodbridge)</td>
</tr>
<tr>
<td>Falle, Sir Bertram G.</td>
<td>Mabane, William</td>
<td>Ruggles-Brise, Colonel E. A.</td>
</tr>
<tr>
<td>Ferguson, Sir John</td>
<td>McCorquodale, M. S.</td>
<td>Runciman, Rt. Hon. Walter</td>
</tr>
<tr>
<td>Foot, Dingle (Dundee)</td>
<td>MacDonald, Rt. Hon. J. R. (Seaham)</td>
<td>Runge, Norah Cecil</td>
</tr>
<tr>
<td>Foot, Isaac (Cornwall, Bodmin)</td>
<td>MacDonald, Malcolm (Bassetlaw)</td>
<td>Salmon, Major Isidore</td>
</tr>
<tr>
<td>Fox, Sir Gifford</td>
<td>Macdonald, Capt. P. D. (I. of W.)</td>
<td>salt, Edward, W.</td>
</tr>
<tr>
<td>Fraser, Captain Ian</td>
<td>McEwen, Captain J. H. F.</td>
<td>Samuel, Sir Arthur Michael (F'nham)</td>
</tr>
<tr>
<td>Fremantle, Sir Francis</td>
<td>McKeag, William</td>
<td>Samuel, Rt. Hon. Sir H. (Darwen)</td>
</tr>
<tr>
<td>Fuller, Captain A. G.</td>
<td>McKie, John Hamilton</td>
<td>Sandeman, Sir A. N. Stewart</td>
</tr>
<tr>
<td>Ganzoni, Sir John</td>
<td>Maclay, Hon. Joseph Paton</td>
<td>Savery, Samuel Servington</td>
</tr>
<tr>
<td>George, Megan A. Lloyd (Anglesea)</td>
<td>McLean, Major Alan</td>
<td>Scone, Lord</td>
</tr>
<tr>
<td>Gilmour, Lt.-Col. Rt. Hon. Sir John</td>
<td>Maclean, Rt. Hn. Sir D. (Corn'll, N.)</td>
<td>Selley, Harry R.</td>
</tr>
<tr>
<td>Glossop, C. W. H.</td>
<td>McLean, Dr. W. H. (Tradeston)</td>
<td>Shaw, Helen B. (Lanark, Bothwell)</td>
</tr>
<tr>
<td>Gluckstein, Louis Halle</td>
<td>Macmillan, Maurice Harold</td>
<td>Skelton, Archibald Noel</td>
</tr>
<tr>
<td>Glyn, Major Ralph G. C.</td>
<td>Macquisten, Frederick Alexander</td>
<td>Slater, John</td>
</tr>
<tr>
<td>Goff, Sir Park</td>
<td>Maitland, Adam</td>
<td>Smiles, Lieut.-Col. Sir Walter D.</td>
</tr>
<tr>
<td>Goodman, Colonel Albert W.</td>
<td>Makins, Brigadier-General Ernest</td>
<td>Smith, R. W. (Aberd'n &amp; Kinc'dine, C.)</td>
</tr>
<tr>
<td>Graham, Fergus (Cumberland, N.)</td>
<td>Mallalieu, Edward Lancelot</td>
<td>Smith-Carington, Neville W.</td>
</tr>
<tr>
<td>Graves, Marjorie</td>
<td>Mander, Geoffrey le M.</td>
<td>Somervell, Donald Bradley</td>
</tr>
<tr>
<td>Gretton, Colonel Rt. Hon. John</td>
<td>Manningham-Buller, Lt.-Col. Sir M.</td>
<td>Somerville, Annesley A. (Windsor)</td>
</tr>
<tr>
<td>Gritten, W. G. Howard</td>
<td>Margesson, Capt. Henry David R.</td>
<td>Sotheron-Estcourt, Captain T. E.</td>
</tr>
<tr>
<td>Guinness, Thomas L. E. B.</td>
<td>Martin, Thomas B.</td>
<td>Southby, Commander Archibald R. J.</td>
</tr>
<tr>
<td>Guy, J. C. Morrison</td>
<td>Mayhew, Lieut.-Colonel John</td>
<td>Spencer, Captain Richard A.</td>
</tr>
<tr>
<td>Hacking, Rt. Hon. Douglas H.</td>
<td>Meller, Richard James</td>
<td>Spender-Clay, Rt. Hon. Herbert H.</td>
</tr>
<tr>
<td>Hamilton, Sir George (Ilford)</td>
<td>Merriman, Sir F. Boyd</td>
<td>Stanley, Lord (Lancaster, Fylde)</td>
</tr>
<tr>
<td>Hamilton, Sir R. W. (Orkney &amp; Ztl'nd)</td>
<td>Mills, Major J. D. (New Forest)</td>
<td>Stanley Hon. O. F. G. (Westmorland)</td>
</tr>
<tr>
<td>Hammersley, Samuel S.</td>
<td>Milne, Charles</td>
<td>Stevenson, James</td>
</tr>
<tr>
<td>Hanbury, Cecil</td>
<td>Milne, Sir John S. Wardlaw-</td>
<td>Stones, James</td>
</tr>
<tr>
<td>Hanley, Dennis A.</td>
<td>Mitchell, Sir W. Lane (Streatham)</td>
<td>Strickland, Captain W. F.</td>
</tr>
<tr>
<td>Hannon, Patrick Joseph Henry</td>
<td>Molson, A. Hugh Eisdale</td>
<td>Stuart, Hon. J. (Moray and Nairn)</td>
</tr>
<tr>
<td>Harris, Sir Percy</td>
<td>Moreing, Adrian C.</td>
<td>Sueter, Rear-Admiral Murray F.</td>
</tr>
<tr>
<td>Hartington, Marquess of</td>
<td>Morgan, Robert H.</td>
<td>Sutcliffe, Harold</td>
</tr>
<tr>
<td>Hartland, George A.</td>
<td>Morris, John Patrick (Salford, N.)</td>
<td>Tate, Mavis Constance</td>
</tr>
<tr>
<td>Harvey, Major s. E. (Devon, Totnes)</td>
<td>Morris-Jones, Dr. J. H. (Denbigh)</td>
<td>Taylor, Vice-Admiral E. A. (P'dd'gt'n, S.)</td>
</tr>
<tr>
<td>Haslam, Sir John (Bolton)</td>
<td>Moss, Captain H. J.</td>
<td>Thomas, James P. L. (Hereford)</td>
</tr>
<tr>
<td>Hellgers, Captain F. F. A.</td>
<td>Muirhead, Major A. J.</td>
<td>Titchfield, Major the Marquess of</td>
</tr>
<tr>
<td>Henderson, Sir Vivian L. (Chelmsf'd)</td>
<td>Munro, Patrick</td>
<td>Todd, Capt. A. J. K. (B'wick-on-T.)</td>
</tr>
<tr>
<td>Heneage, Lieut.-Colonel Arthur P.</td>
<td>Nation, Brigadier-General J. J. H.</td>
<td>Train, John</td>
</tr>
<tr>
<td>Hoare, Lt.-Col. Rt. Hon. Sir S. J. G.</td>
<td>Nicholson, Godfrey (Morpeth)</td>
<td>Tryon, Rt. Hon. George Clement</td>
</tr>
<tr>
<td>Holdsworth, Herbert</td>
<td>Nicholson, Rt. Hn. W. G. (Petersf'ld)</td>
<td>Vaughan-Morgan, Sir Kenyon</td>
</tr>
<tr>
<td>Hope, Capt. Arthur O. J. (Aston)</td>
<td>North, Captain Edward T.</td>
<td>Ward, Lt.-Col. Sir A. L. (Hull)</td>
</tr>
<tr>
<td>Hornby, Frank</td>
<td>Nunn, William</td>
<td>Ward, Irene Mary Bewick (Wallsend)</td>
</tr>
<tr>
<td>Horobin, Ian M.</td>
<td>Oman, Sir Charles William C.</td>
<td>Warrender, Sir Victor A. G.</td>
</tr>
<tr>
<td>Horsbrugh, Florence</td>
<td>O'Neill, Rt. Hon. Sir Hugh</td>
<td>Wedderburn, Henry James Scrymgeour</td>
</tr>
<tr>
<td>Howitt, Dr. Alfred B.</td>
<td>Ormsby-Gore, Rt. Hon. William G. A.</td>
<td>Weymouth, Viscount</td>
</tr>
<tr>
<td>Hudson, Capt. A. U. M. (Hackney, N.)</td>
<td>Palmer, Francis Noel</td>
<td>White, Henry Graham</td>
</tr>
<tr>
<td>Hume, Sir George Hopwood</td>
<td>Patrick, Colin M.</td>
<td>Williams, Charles (Devon, Torquay)</td>
</tr>
<tr>
<td>Hunter, Dr. Joseph (Dumfries)</td>
<td>Peake, Captain Osbert</td>
<td>Williams, Herbert G. (Croydon, S.)</td>
</tr>
<tr>
<td>Hurd, Sir Percy</td>
<td>Pearson, William G.</td>
<td>Wills, Wilfrid D.</td>
</tr>
<tr>
<td>Hutchison, W. D. (Essex, Romford)</td>
<td>Peat, Charles U.</td>
<td>Wilson, Clyde T. (West Toxteth)</td>
</tr>
<tr>
<td>Jackson, Sir Henry (Wandsworth, C.)</td>
<td>Perkins, Walter R. D.</td>
<td>Windsor-Clive, Lieut.-Colonel George</td>
</tr>
<tr>
<td>Jackson, J. C. (Heywood &amp; Radcliffe)</td>
<td>Petherick, M.</td>
<td>Womersley, Walter James</td>
</tr>
<tr>
<td>James, Wing.-Com. A. W. H.</td>
<td>Peto, Sir Basil E.(Devon, Barnstaple)</td>
<td>Wood, Rt. Hon. Sir H. Kingsley</td>
</tr>
<tr>
<td>Jesson, Major Thomas E.</td>
<td>Peto, Geoffrey K. (W'verh'pt'n, Bilst'n)</td>
<td>Wood, Sir Murdoch McKenzie (Banff)</td>
</tr>
<tr>
<td>Johnstone, Harcourt (S. Shields)</td>
<td>Pike, Cecil F.</td>
<td>Worthington, Dr. John V.</td>
</tr>
<tr>
<td>Jones, Henry Haydn (Merioneth)</td>
<td>Potter, John</td>
<td>Young, Rt. Hon. Sir Hilton (S'v'noaks)</td>
</tr>
<tr>
<td>Jones, Lewis (Swansea, West)</td>
<td>Pownall, Sir Assheton</td>
<td>Young, Ernest J. (Middlesbrough, E.)</td>
</tr>
<tr>
<td>Ker, J. Campbell</td>
<td>Preston, Sir Walter Rueben</td>
<td></td>
</tr>
<tr>
<td>Kerr, Hamilton W.</td>
<td>Procter, Major Henry Adam</td>
<td>TELLERS FOR THE AYES.&#x2014;</td>
</tr>
<tr>
<td>Knatchbull, Captain Hon. M. H. R.</td>
<td>Pybus, Percy John</td>
<td>Sir Frederick Thomson and Lord</td>
</tr>
<tr>
<td>Knebworth, Viscount</td>
<td>Raikes, Henry V. A. M.</td>
<td>Erskine.</td>
</tr>
<tr>
<td>Knight, Holford</td>
<td>Ramsay, Capt. A. H. M. (Midlothian)</td>
<td></td>
</tr>


<tr>
<td align="center" colspan="3">
<b>NOES.</b>
</td>
</tr>
<tr>
<td>Adams, D. M. (Poplar, South)</td>
<td>Daggar, George</td>
<td>Grundy, Thomas W.</td>
</tr>
<tr>
<td>Attlee, Clement Richard</td>
<td>Duncan, Charles (Derby, Claycross)</td>
<td>Hall, F. (York, W.R., Normanton)</td>
</tr>
<tr>
<td>Batey, Joseph</td>
<td>Edwards, Charles</td>
<td>Healy, Cahir</td>
</tr>
<tr>
<td>Brown, C. W. E. (Notts., Mansfield)</td>
<td>Greenwood, Rt. Hon. Arthur</td>
<td>Hirst, George Henry</td>
</tr>
<tr>
<td>Buchanan, George.</td>
<td>Grenfell, David Rees (Glamorgan)</td>
<td>Jenkins, Sir William</td>
</tr>
<tr>
<td>Cocks, Frederick Seymour</td>
<td>Griffiths, T. (Monmouth, Pontypool)</td>
<td>Jones, Morgan (Caerphilly)</td>
</tr>

<col>1780</col>
<image src="S5CV0266P0I0896"></image>
<col>1781</col>

<tr>
<td>Kirkwood, David</td>
<td>McGovern, John</td>
<td>Williams, David (Swansea, East)</td>
</tr>
<tr>
<td>Lansbury, Rt. Hon. George</td>
<td>Maclean, Neil (Glasgow, Govan)</td>
<td>Williams, Edward John (Ogmore)</td>
</tr>
<tr>
<td>Lawson, John James</td>
<td>Maxton, James</td>
<td>Williams, Dr. John H. (Lianelly)</td>
</tr>
<tr>
<td>Leonard, William</td>
<td>Milner, Major James</td>
<td>Williams, Thomas (York., Don Valley)</td>
</tr>
<tr>
<td>Logan, David Gilbert</td>
<td>Parkinson, John Allen</td>
<td></td>
</tr>
<tr>
<td>Lunn, William</td>
<td>Price, Gabriel</td>
<td>TELLERS FOR THE NOES.&#x2014;</td>
</tr>
<tr>
<td>Macdonald, Gordon (Ince)</td>
<td>Thorne, William James</td>
<td>Mr. John and Mr. Groves.</td>
</tr>
</table>|
  end
end



describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1983, 12, 21)
    @sitting_date_text = 'Wednesday 21 December 1983'
    @sitting_title = 'House of Commons'
    @sitting_start_column = '411'
    @sitting_end_column = '450'
    source_file = mock_model(SourceFile, :volume => mock_model(Volume), :series_number=>5)
    file = 'housecommons_split_division_table_in_different_sections.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, source_file

    @sitting.save!

    @first_section = @sitting.debates.sections.first
    @second_section = @sitting.debates.sections[1]

    @division_placeholder = @first_section.contributions[2]
    @division = @division_placeholder.division

  end

  it_should_behave_like "All sittings"

  # it 'should not create division placeholder for continuous division element that occurs after to the first division after "The House divided" text' do
    # @second_section.contributions.size.should == 1
  # end

  it 'should have a division placeholder after the "The House divided" text' do
    @division_placeholder.should be_an_instance_of(DivisionPlaceholder)
  end

  it 'should set complete division text on the single placeholder contribution' do
    @division_placeholder.text.should == %Q|<table>
<tr>
<td><b>[Division No. 115]</b></td>
<td align="right"><b>[4.45 pm</b></td>
</tr>
<tr>
<td align="center" colspan="2"><b>AYES</b></td>
</tr>
<tr>
<td>Adley, Robert</td>
<td>Budgen, Nick</td>
</tr>
<tr>
<td>Aitken, Jonathan</td>
<td>Bulmer, Esmond</td>
</tr>


<tr>
<td>Godman, Dr Norman</td>
<td>Nellist, David</td>
</tr>
<tr>
<td>Hamilton, W. W. <i>(Central Fife)</i></td>
<td>O'Brien, William</td>
</tr>
</table>|
  end

end

