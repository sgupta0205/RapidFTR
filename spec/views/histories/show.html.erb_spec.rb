require 'spec_helper'
class FakeRecordWithHistory
  attr_reader :id
  def initialize user = "Bob", created = "31/12/2010 22:06"
    @id = "ChildId"
   @fields = {
     "histories"=> [],
     "created_at" => created,
     "created_by" => user
   }
  end
  def add_history history
    @fields["histories"].unshift(history)
  end
  def add_single_change username, date, field, from, to
    self.add_history({
             "changes" => {
                 field => {
                     "from" => from,
                     "to" => to
                 }
             },
             "user_name" => username,
             "datetime" => date
          })
  end
  def [](field)
     @fields[field]
   end
end
describe "histories/show.html.erb" do

  describe "child history" do
    before do
      FormSection.stub!(:all_child_field_names).and_return(["age", "last_known_location", "current_photo_key"])
    end
    describe "rendering history for a newly created record" do
      it "should render only the creation record" do
        child = FakeRecordWithHistory.new "Bob", "Yesterday"
        assigns[:child] = child
        render
      	response.should have_tag(".history-details") do
          with_tag("li", /Yesterday Record created by Bob/)
      	end
      end
    end
    describe "rendering changes to photos" do
      it "should render photo change record when updating a photo" do
        child = FakeRecordWithHistory.new "Bob", "Yesterday"
        child.add_single_change "rapidftr", "31/12/2010 20:55", "current_photo_key", "OldPhoto", "NewPhoto"

        assigns[:child] = child
        render

      	response.should have_tag(".history-details") do
          with_tag("li", /Photo changed/)
      	end
      end
      it "should render photo change record with links when adding a photo to an existing record for first time" do
        child = FakeRecordWithHistory.new "Bob", "Yesterday"
        child.add_single_change "rapidftr", "31/12/2010 20:55", "current_photo_key", nil, "NewPhoto"

        assigns[:child] = child
        render

      	response.should have_tag(".history-details") do
          with_tag("li", /Photo  added/)
          with_tag("li", /Photo  added/)
      	end
      end
    end
    describe "rendering changes to audio" do
      it "should render audio change record" do
        child = FakeRecordWithHistory.new
        child.add_single_change "rapidftr", "31/12/2010 20:55", "recorded_audio", "First", "Second"

        assigns[:child] = child
        render

      	response.should have_tag(".history-details") do
      		with_tag("li", /31\/12\/2010 20:55 Audio changed from First to Second by rapidftr/)
      	end
      end
      it "should render audio change record with links when adding a sound file to an existing record for first time" do
        child = FakeRecordWithHistory.new
        child.add_single_change "rapidftr", "31/12/2010 20:55", "recorded_audio", nil, "Audio"

        assigns[:child] = child
        render

      	response.should have_tag(".history-details") do
          with_tag("li", /31\/12\/2010 20:55 Audio Audio added by rapidftr/)
      	end
      end
    end
    describe "rendering several history entries" do
      it "should order history log from most recent change to oldest change" do
        child = FakeRecordWithHistory.new
        child.add_single_change "rapidftr", "20/02/2010 12:04", "age", "6", "7"
        child.add_single_change "rapidftr", "20/02/2010 13:04", "last_known_location", "Haiti", "Santiago"
        child.add_single_change "rapidftr", "20/02/2011 12:04", "age", "7", "8"

        assigns[:child] = child
        render

        response.should have_tag(".history-details") do
          with_tag("li", /Age changed from 7 to 8/)
          with_tag("li", /Last known location changed from Haiti to Santiago/)
          with_tag("li", /Age changed from 6 to 7/)
          with_tag("li", /Record created by/)
        end
      end
    end
  end
end
