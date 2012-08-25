require File.dirname(__FILE__) + '/../spec_helper'

describe SourceFile do 
  
  before do 
    SourceFile.stub!(:log_to_stdout)
  end
 
  describe 'the class' do
    
    it 'should respond to from_file' do
      SourceFile.respond_to?(:from_file).should be_true
    end
  
  end

  describe 'when asked for the error slug for an error message' do 
  
    it 'should ask for the normalized text' do
      Acts::Slugged.should_receive(:normalize_text).with('Error Message')
      SourceFile.error_slug('Error Message')
    end
  
  end
  
  describe 'when asked for the error message for an error slug' do 
  
    it 'should get the error summary' do 
      SourceFile.should_receive(:error_summary).and_return([[], nil])
      SourceFile.error_from_slug('test-error')
    end
    
    it 'should return the error that matches the slug' do 
      SourceFile.should_receive(:error_summary).and_return([['First Error','Test Error', 'Other Error'], nil])
      SourceFile.error_from_slug('test-error').should == 'Test Error'
    end
  
  end
  
  describe "when asked for it's header data file" do 
  
    it 'should ask for the first of it\'s files called "header.xml"' do
      source_file = SourceFile.new
      mock_data_file_association = mock('data file association')
      source_file.stub!(:data_files).and_return(mock_data_file_association)
      mock_data_file_association.should_receive(:find_by_name).with('header.xml')
      source_file.header_data_file
    end 

  end

  describe  ' when asked for missing columns' do 

    it 'should return an empty array if it has no errors logged' do 
      SourceFile.new.missing_columns.should == []
    end
  
    it 'should return a list of column numbers if it has errors logged about missing columns' do 
      source_file = SourceFile.new

      source_file.add_log 'Missing column? Got: 593, expected 591 (last column 590)'
      source_file.add_log 'Missing column? Got: 35, expected 34 (last column 33)'
      source_file.missing_columns.should == ['591', '34']
    end

  end

  describe  ' when asked for missing images' do 

    it 'should return an empty array if it has no errors logged' do 
      SourceFile.new.missing_images.should == []
    end
  
    it 'should return a list of image numbers if it has errors logged about missing image' do 
      source_file = SourceFile.new
      source_file.add_log 'Missing image? Got: 593, expected 591 (last image 590)'
      source_file.add_log 'Missing image? Got: 35, expected 34 (last image 33)'
      source_file.missing_images.should == ['591', '34']
    end

  end

  describe  ' when asked for a bad session tag' do 

    it 'should return nil if it has no errors logged' do 
      SourceFile.new.bad_session_tag.should == nil
    end
  
    it 'should return the contents of the bad session tag if there is one' do 
      source_file = SourceFile.new
      source_file.add_log 'Badly formatted session tag: In the bleak midwinter'
      source_file.bad_session_tag.should == 'In the bleak midwinter'
    end

  end

  describe  ' when asked for dates outside sessions' do 

    it 'should return an empty array if it has no errors logged' do 
      SourceFile.new.dates_outside_session.should == []
    end
  
    it 'should return the any dates logged as being outside the session dates' do 
      source_file = SourceFile.new
      source_file.add_log 'Date not in session years: 2004-02-01'
      source_file.dates_outside_session.should == ['2004-02-01']
    end

  end


  describe  ' when asked for large gaps between dates' do 

    it 'should return an empty array if it has no errors logged' do 
      SourceFile.new.large_gaps_between_dates.should == []
    end
  
    it 'should return the any pairs of dates logged as having large gaps between them' do 
      source_file = SourceFile.new
      source_file.add_log 'Large gap between dates: 2005-10-01 and 2005-01-01'
      source_file.large_gaps_between_dates.should == ['2005-10-01 and 2005-01-01']
    end

  end

  describe  'when asked for corrected dates' do 
  
    it 'should return an empty array if it has no errors logged' do 
      SourceFile.new.corrected_dates.should == []
    end
  
    it 'should return a hash of attributes for each corrected date' do 
      source_file = SourceFile.new
      source_file.add_log 'Bad date format: date format="1979-11-11">Wednesday 28 November 1979</date> Suggested date: 1979-11-28'
      source_file.corrected_dates.should == [{:original_text  => 'Wednesday 28 November 1979',
                                              :extracted_date => '1979-11-11',
                                              :corrected_date => '1979-11-28'}]
    end


  end


  describe "in general" do

    it 'should return its associated volume' do
      volume = Volume.new
      source_file = SourceFile.new(:volume => volume)
      source_file.volume.should == volume
    end

    it "should validate the uniqueness of the source file name" do
      source_file = SourceFile.new(:name => "popular_name")
      source_file.save!
      second_source_file = SourceFile.new(:name => "popular_name")
      second_source_file.valid?.should be_false
    end

    it 'should default xsd_validated field to nil' do
      source_file = SourceFile.new
      source_file.valid?.should be_true
      source_file.xsd_validated.should be_nil
    end

    it 'should create error summary hash correctly' do
      source_file_x = SourceFile.new :name => 'x'
      source_file_x.add_log 'Bad date format: date format="1980-07-28">Monday 22 July 1980'
      source_file_x.add_log 'Missing column? Got: 593, expected 591 (last column 590)'
      source_file_x.add_log 'Missing or badly formatted session tag'
      source_file_x.save!
      source_file_x.log.should == %Q[Bad date format: date format="1980-07-28">Monday 22 July 1980\nMissing column? Got: 593, expected 591 (last column 590)\nMissing or badly formatted session tag]

      source_file_y = SourceFile.new :name => 'y'
      source_file_y.add_log 'Missing column? Got: 35, expected 34 (last column 33)'
      source_file_y.save!

      source_file_z = SourceFile.new :name => 'z'
      source_file_z.add_log 'Bad date format: date format="1979-11-11">Wednesday 28 November 1979'
      source_file_z.save!

      error_types, hash = SourceFile.get_error_summary
      error_types.size.should == 3

      hash['Bad date format'].should_not be_nil
      hash['Missing column'].should_not be_nil
      hash['Missing or badly formatted session tag'].should_not be_nil

      hash['Bad date format'].size.should == 2
      hash['Missing column'].size.should == 2
      hash['Missing or badly formatted session tag'].size.should == 1

      error_types[0].should == 'Bad date format'
      error_types[1].should == 'Missing column'
      error_types[2].should == 'Missing or badly formatted session tag'
    end
  end

  describe  " when giving house, volume, series and part information" do 
  
    it 'should give a volume number of 296 if it has name "S3V0296P0.xml"' do 
      source_file = SourceFile.new(:name => 'S3V0296P0.xml')
      source_file.volume_number.should == 296
    end
  
    it 'should give a volume number of 422 if it has name "S6CV0422P2.xml"' do 
      source_file = SourceFile.new(:name => 'S6CV0422P2.xml')
      source_file.volume_number.should == 422
    end
  
    it 'should give a series number of 3 if it has name "S3V0296P0.xml"' do 
      source_file = SourceFile.new(:name => 'S3V0296P0.xml')
      source_file.series_number.should == 3
    end
  
    it 'should give a part number of 0 if it has name "S3V0296P0.xml"' do 
      source_file = SourceFile.new(:name => 'S3V0296P0.xml')
      source_file.part_number.should == 0
    end
  
    it 'should give a part number of 2 if it has name "S6CV0422P2.xml"' do 
      source_file = SourceFile.new(:name => 'S6CV0422P2.xml')
      source_file.part_number.should == 2
    end
  
    it 'should give a series house of "commons" if it has name "S6CV0422P2.xml"' do 
      source_file = SourceFile.new(:name => 'S6CV0422P2.xml')
      source_file.series_house.should == 'commons'
    end
  
    it 'should give a series house of "lords" if it has name "S5LV0436P0.xml"' do 
      source_file = SourceFile.new(:name => 'S5LV0436P0.xml')
      source_file.series_house.should == 'lords'
    end
  
    it 'should give a series house of "both" if it has name "S3V0296P0.xml"' do 
      source_file = SourceFile.new(:name => 'S3V0296P0.xml')
      source_file.series_house.should == 'both'
    end
  
    it 'should return a hash of volume info for a filename' do 
      filename = "S6CV0422P2.xml"
      SourceFile.info_from_filename(filename).should == { :house  => 'commons',
                                                          :series => 6,
                                                          :volume => 422, 
                                                          :part   => 2 }
    end
  
  end

end