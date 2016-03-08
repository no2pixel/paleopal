class EntriesController < ApplicationController
  def new
    if current_user
      @entry = Entry.new(date: Date.today, meal: "Choose Meal")
      @entry.meal = params["meal"] if params["meal"]
      @entry.date = params["date"] if params["date"]
    else
      unauthenticated_user_error
    end
  end

  def index
    @entries = current_user.entries.group_by do |entry|
      entry.date
    end
  end

  def create
    @entry = Entry.create(entry_params)
    @entry.user_id = current_user.id
    if @entry.save
      meal_data = { ingredients: params["entry"]["ingredients"].split(/ *, */) }
      calc_nutrients(meal_data)
      redirect_to user_dashboard_path
      flash[:success] = "New meal logged!"
    else
      flash[:error] = @entry.errors.full_messages.join(", ")
      redirect_to new_entry_path
    end
  end

  def show
    if current_user
      @entry = Entry.find(params[:id])
    else
      unauthenticated_user_error
    end
  end

  def calc_nutrients(meal_data)
    summed_nutrients = process_entry_data(meal_data)
    @entry.update_attributes(summed_nutrients)
    @entry.save
  end

  def get_api_nutrients
    if params[:ingredients]
      meal_data = { ingredients: params[:ingredients].split(/ *, */) }
      summed_nutrients = process_entry_data(meal_data)
      render :json => { :result => "success", :nutrients => summed_nutrients }
    else
      flash[:error] = "You don't belong here."
      redirect_to new_entry_path
    end
  end

  private

  def process_entry_data(meal_data)
    ns = NutritionService.new
    nutrients = ns.get_nutrition_values(meal_data)
    Macronutrients.sum_macronutrients(nutrients)
  end

  def entry_params
    params.require(:entry).permit(:date,
                                  :meal,
                                  :ingredients,
                                  :fat,
                                  :carbs,
                                  :protein,
                                  :notes,
                                  :user_id)
  end
end
