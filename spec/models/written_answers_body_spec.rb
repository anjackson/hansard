require File.dirname(__FILE__) + '/section_spec_helper'

describe WrittenAnswersBody do
  before do
    @title = "title"
    @id_hash = {:id=>'stuff'}

    @parent = mock_model(Section)
    @parent.stub!(:title).and_return(@title)
    @parent.stub!(:id_hash).and_return(@id_hash)

    @body = WrittenAnswersBody.new
    @body.stub!(:parent_section).and_return(@parent)
  end

  it "should for title, return the title of it's parent section" do
    @body.title.should == @title
  end

  it "should for id_hash, return the id_hash of it's parent section" do
    @body.id_hash.should == @id_hash
  end

end
