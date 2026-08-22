# frozen_string_literal: true

RecordingStudioSitemaps::Engine.routes.draw do
  get "rebuild", to: "rebuilds#create", as: :rebuild
  post "rebuild", to: "rebuilds#create"
end
