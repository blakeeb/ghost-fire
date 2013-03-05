class RoomsController < ApplicationController
  def show
    @room = params[:id]
    @resetName = params[:reset]
  end
end