# App template for generating acts_as_trivia enable applications
# See http://github.com/balinterdi/acts_as_trivia/tree/master

#TODO: add context-dependent (e.g xxx) strings and defaults. For example, if country has a name attribute, 
# offer that as default when asking for the value to be displayed

def ask_with_default(question, default='')
  user_answer = ask(question).strip
  user_answer.empty? ? default : user_answer
end

# generate a model class
model_name_and_attributes = ask_with_default("Define the model in Rails resource generate style. (e.g country name:string population:integer)", "country name:string population:integer")
model_name_and_attributes = model_name_and_attributes.split(/\s+/).select { |token| !token.empty? }
model_name, attributes = model_name_and_attributes.first.downcase, model_name_and_attributes[1..-1]
generate(:resource, model_name, *attributes.join(' '))

# generating a simple user class
generate(:resource, "user", "login:string", "password:string")

# install the acts_as_trivia gem
gem "balinterdi-acts_as_trivia", :lib => "acts_as_trivia", :source => "http://gems.github.com"
rake "gems:unpack"

# create acts_as_trivia related controllers and views and create a trivia question
trivia_about = ask_with_default("Which attribute of the model should the trivia be about? (e.g population)", "population")
trivia_displayed = ask_with_default("Which attribute of the model should be displayed in the trivia? (e.g name)", "name")
generate(:acts_as_trivia, model_name, trivia_about, trivia_displayed)

rake "db:migrate"

# create a default user
user_name = ask("A user name to create?")
run %(./script/runner "User.create(:login => '#{user_name}', :password => '#{user_name}')")

# create some model instances for the trivia (e.g countries)
attribute_names = attributes.map{ |attr_and_type| attr_and_type.split(":").first }
num_model_instances = ask_with_default("How many #{model_name} instances would you like to create? (0 to skip this)", 0).to_i
num_model_instances.times do |i|
  puts "#{i+1}. instance"
  attr_hash = {}
  attribute_names.each do |attr|
    value = ask("#{attr}:")
    attr_hash[attr] = value
  end
  attr_values_stringified = attr_hash.map { |attr, value| ":#{attr} => '#{value}'"}.join(", ")
  run %(./script/runner "model = #{model_name.camelize}.create(#{attr_values_stringified})")
end

file "app/controllers/trivia_answers_controller.rb", <<-EOS
class TriviaAnswersController < ApplicationController
  before_filter :find_trivia
  before_filter :find_user

  def new
    @trivia_objects = @trivia.get_subjects
  end

  def create
    @trivia_answer = TriviaAnswer.new(:user_id => @user, :trivia_id => @trivia)
    @trivia_answer.points = @trivia_answer.assess(params[@trivia.on.to_sym][@trivia.about.to_sym])
    if @trivia_answer.save
      flash[:ok] = "You got \#{@trivia_answer.points} right"
      # show the solution for the trivia
      redirect_to user_trivia_trivia_answer_path(@user, @trivia, @trivia_answer)
    end
  end

  def show
    @trivia_answer = TriviaAnswer.find(params[:id])
  end

  private
  def find_trivia
    @trivia = Trivia.find(params[:trivia_id])
  end
  def find_user
    @user = User.find(params[:user_id])
  end

end
EOS

file "app/views/trivia_answers/new.html.erb", <<-EOS
<% form_for :trivia_answer, @trivia_answer, :url => user_trivia_trivia_answers_path(@user, @trivia) do |f| -%>
  <%= trivia_user_panel(@trivia) %>
  <%= f.submit "Submit answer" %>
<% end -%>
EOS

file "app/views/trivia_answers/show.html.erb", <<-EOS
<% with_each_solution_value(@trivia) do |i, name, value| -%>
  <p><%= "\#{i}. \#{name}: \#{value}" %></p>
<% end -%>
EOS

