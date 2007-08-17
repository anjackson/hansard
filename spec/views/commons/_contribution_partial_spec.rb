require File.dirname(__FILE__) + '/../../spec_helper'

describe "_contribution partial", "when passed procedural contribution" do

  before do
    @text = '[MADAM SPEAKER <i>in the Chair</i>]'

    @procedural = mock_model(ProceduralContribution)
    @procedural.should_receive(:is_a?).with(ProceduralContribution).and_return(true)
    @procedural.should_receive(:text).and_return(@text)
    @controller.template.stub!(:contribution).and_return(@procedural)

    render 'commons/_contribution.haml'
  end

  it 'should show speaker in chair as p with class procedural' do
    response.should have_tag('p.procedural', '[MADAM SPEAKER in the Chair]')
  end

end
