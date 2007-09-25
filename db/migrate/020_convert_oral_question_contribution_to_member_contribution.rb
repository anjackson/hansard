class ConvertOralQuestionContributionToMemberContribution < ActiveRecord::Migration

  def self.up
    puts "looking up oral question contributions to convert ..."

    eval 'class OralQuestionContribution < Contribution; end'
    question_contributions = OralQuestionContribution.find(:all)

    puts "converting #{question_contributions.size} oral question contributions in to member contributions ..."

    question_contributions.each do |contribution|
      contribution.type = 'MemberContribution'
      contribution.save!
    end
  end

  def self.down
    # one way migration, not possible to revert
  end
end
