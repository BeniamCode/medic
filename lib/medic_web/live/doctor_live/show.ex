defmodule MedicWeb.DoctorLive.Show do
  @moduledoc """
  Doctor profile view with industry-standard booking layout.
  Inspired by Zocdoc/Doctolib - stacked design with booking prominent.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias MedicWeb.DoctorLive.BookingComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50/50">
      <%!-- Hero Section / Professional Identity --%>
      <div class="bg-base-100 border-b border-base-200 shadow-sm sticky top-0 z-30">
        <div class="max-w-6xl mx-auto py-6 px-4">
          <.link navigate={~p"/search"} class="btn btn-ghost btn-xs sm:btn-sm gap-1 mb-4 text-base-content/60 hover:text-primary transition-colors">
            <.icon name="hero-arrow-left" class="w-4 h-4" /> <%= gettext("Back to search") %>
          </.link>

          <div class="flex flex-col md:flex-row gap-6 md:gap-8 items-start">
            <%!-- Doctor Avatar --%>
            <div class="avatar placeholder shrink-0">
              <div class="w-32 h-32 md:w-40 md:h-40 rounded-2xl bg-gradient-to-br from-primary/10 to-primary/5 ring-1 ring-base-200 shadow-md">
                <%= if @doctor.profile_image_url do %>
                  <img src={@doctor.profile_image_url} alt={"Dr. #{@doctor.first_name}"} class="object-cover" />
                <% else %>
                   <span class="text-5xl text-primary/40"><.icon name="hero-user" class="w-20 h-20" /></span>
                <% end %>
              </div>
            </div>

            <%!-- Doctor Info Header --%>
            <div class="flex-1 w-full">
              <div class="flex flex-col md:flex-row md:justify-between md:items-start gap-4">
                <div>
                  <h1 class="text-3xl md:text-4xl font-bold tracking-tight text-base-content">
                    <%= @doctor.title || "Dr." %> <%= @doctor.first_name %> <%= @doctor.last_name %>
                  </h1>
                  
                  <div class="mt-2 text-lg text-primary font-medium flex flex-wrap items-center gap-x-2 gap-y-1">
                    <span><%= (@doctor.specialty && @doctor.specialty.name_en) || "General Practice" %></span>
                    <%= if @doctor.years_of_experience do %>
                      <span class="w-1.5 h-1.5 rounded-full bg-base-300"></span>
                      <span class="text-base-content/70 text-base"><%= @doctor.years_of_experience %> <%= gettext("Years Exp.") %></span>
                    <% end %>
                  </div>
                  
                  <%= if @doctor.hospital_affiliation do %>
                    <div class="mt-2 flex items-center gap-2 text-base-content/80">
                      <.icon name="hero-building-office-2" class="w-5 h-5 text-base-content/40" />
                      <span class="font-medium"><%= @doctor.hospital_affiliation %></span>
                    </div>
                  <% end %>
                  
                  <%= if @doctor.registration_number do %>
                    <div class="flex items-center gap-2 mt-1 text-sm text-base-content/60 font-mono">
                      <span><%= gettext("Reg:") %> <%= @doctor.registration_number %></span>
                    </div>
                  <% end %>
                </div>

                <%!-- Rating & Verification Badge --%>
                <div class="flex flex-col items-end gap-2">
                  <div class="flex items-center gap-2 bg-base-100 border border-base-200 shadow-sm rounded-xl px-4 py-2">
                    <div class="flex items-center gap-1">
                      <.icon name="hero-star-solid" class="w-6 h-6 text-warning" />
                      <span class="text-2xl font-bold"><%= Float.round(@doctor.rating || 0.0, 1) %></span>
                    </div>
                    <div class="h-8 w-px bg-base-200 mx-1"></div>
                    <div class="flex flex-col leading-none text-xs text-base-content/60">
                      <span class="font-bold text-base-content"><%= @doctor.review_count || 0 %></span>
                      <span><%= gettext("Verified Reviews") %></span>
                    </div>
                  </div>

                  <%= if @doctor.verified_at do %>
                    <div class="badge badge-success badge-lg gap-1.5 text-success-content shadow-sm py-4">
                      <.icon name="hero-check-badge" class="w-5 h-5" /> <%= gettext("Verified Profile") %>
                    </div>
                  <% end %>
                </div>
              </div>
              
              <%!-- Action Buttons (Mobile Only) --%>
               <div class="md:hidden mt-6 flex gap-3">
                  <a href="#booking" class="btn btn-primary flex-1"><%= gettext("Book Appointment") %></a>
                  <%= if @doctor.telemedicine_available do %>
                     <button class="btn btn-outline flex-1">
                       <.icon name="hero-video-camera" class="w-5 h-5" /> <%= gettext("Video Visit") %>
                     </button>
                  <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Booking Section (Central & Big) --%>
      <div class="bg-base-100 border-b border-base-200 shadow-sm py-8">
        <div class="max-w-4xl mx-auto px-4">
             <div class="card bg-base-100 shadow-xl border border-primary/20 ring-1 ring-primary/10">
                <div class="card-body p-6 md:p-8">
                   <div class="flex flex-col md:flex-row items-center justify-between gap-4 mb-6 border-b border-base-200 pb-4">
                      <div class="flex items-center gap-3">
                        <div class="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                          <.icon name="hero-calendar-days" class="w-6 h-6" />
                        </div>
                        <div>
                           <h2 class="text-2xl font-bold"><%= gettext("Book an Appointment") %></h2>
                           <p class="text-base-content/70"><%= gettext("Select a time that works for you") %></p>
                        </div>
                      </div>
                      
                      <div class="flex flex-col items-end gap-1">
                         <%= if @doctor.consultation_fee do %>
                            <div class="flex items-baseline gap-1">
                               <span class="text-sm font-medium text-base-content/60"><%= gettext("Consultation Fee:") %></span>
                               <span class="text-xl font-bold text-primary">€<%= @doctor.consultation_fee %></span>
                            </div>
                         <% end %>
                         <%= if @doctor.telemedicine_available do %>
                            <div class="badge badge-info gap-1 text-xs">
                               <.icon name="hero-video-camera" class="w-3 h-3" /> <%= gettext("Video Available") %>
                            </div>
                         <% end %>
                      </div>
                   </div>

                   <.live_component
                      module={BookingComponent}
                      id="booking"
                      doctor={@doctor}
                      current_user={@current_user}
                   />
                </div>
             </div>
        </div>
      </div>

      <%!-- Main Content Grid --%>
      <div class="max-w-6xl mx-auto py-8 px-4">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          <%!-- Left Column: Clinical & Bio (2/3) --%>
          <div class="lg:col-span-2 space-y-8">
            
            <%!-- 🧠 II. Clinical Expertise & Focus --%>
            <section class="card bg-base-100 shadow-md border border-base-200 overflow-hidden">
               <div class="bg-primary/5 px-6 py-4 border-b border-primary/10 flex items-center gap-3">
                  <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                    <.icon name="hero-academic-cap" class="w-6 h-6" />
                  </div>
                  <h2 class="text-xl font-bold text-base-content"><%= gettext("Clinical Expertise") %></h2>
               </div>
               <div class="card-body p-6 space-y-6">
                  
                  <%!-- Sub-Specialties --%>
                   <%= if @doctor.sub_specialties != [] do %>
                    <div>
                      <h3 class="text-sm font-semibold uppercase tracking-wider text-base-content/50 mb-3"><%= gettext("Specialized Focus") %></h3>
                      <div class="flex flex-wrap gap-2">
                        <%= for item <- @doctor.sub_specialties do %>
                          <span class="badge badge-lg badge-outline border-primary/30 text-primary-focus bg-primary/5 px-4 py-3"><%= item %></span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>

                  <div class="grid md:grid-cols-2 gap-6">
                    <%!-- Procedures --%>
                    <%= if @doctor.clinical_procedures != [] do %>
                      <div class="bg-base-50 rounded-xl p-4 border border-base-200/50">
                        <h3 class="font-semibold mb-3 flex items-center gap-2">
                          <.icon name="hero-clipboard-document-list" class="w-4 h-4 text-secondary" /> <%= gettext("Common Procedures") %>
                        </h3>
                        <ul class="space-y-1.5 text-sm text-base-content/80 marker:text-secondary list-disc pl-4">
                          <%= for item <- @doctor.clinical_procedures do %>
                            <li><%= item %></li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>

                    <%!-- Conditions --%>
                    <%= if @doctor.conditions_treated != [] do %>
                       <div class="bg-base-50 rounded-xl p-4 border border-base-200/50">
                        <h3 class="font-semibold mb-3 flex items-center gap-2">
                          <.icon name="hero-heart" class="w-4 h-4 text-error/80" /> <%= gettext("Conditions Treated") %>
                        </h3>
                        <ul class="space-y-1.5 text-sm text-base-content/80 marker:text-error/80 list-disc pl-4">
                          <%= for item <- @doctor.conditions_treated do %>
                            <li><%= item %></li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>
                  </div>
               </div>
            </section>

             <%!-- About Bio --%>
            <%= if @doctor.bio do %>
              <section class="card bg-base-100 shadow-md border border-base-200">
                <div class="card-body p-8">
                  <div class="flex items-center gap-3 mb-4">
                     <h2 class="text-xl font-bold"><%= gettext("About Dr.") %> <%= @doctor.last_name %></h2>
                     <div class="h-px bg-base-200 flex-1"></div>
                  </div>
                  <article class="prose prose-sm md:prose-base max-w-none text-base-content/80">
                    <p class="whitespace-pre-line leading-relaxed"><%= @doctor.bio %></p>
                  </article>
                  
                  <%!-- Languages Spoken --%>
                  <%= if @doctor.languages != [] do %>
                    <div class="mt-8 pt-6 border-t border-base-200 flex items-center gap-4">
                       <span class="text-sm font-semibold text-base-content/60"><%= gettext("Languages Spoken:") %></span>
                       <div class="flex flex-wrap gap-2">
                          <%= for lang <- @doctor.languages do %>
                            <div class="badge badge-ghost"><%= lang %></div>
                          <% end %>
                       </div>
                    </div>
                  <% end %>
                </div>
              </section>
            <% end %>

            <%!-- Research & Trust Section --%>
            <%= if @doctor.board_certifications != [] || @doctor.awards != [] || @doctor.publications != [] do %>
              <section class="card bg-base-100 shadow-sm border border-base-200">
                <div class="card-body p-6">
                   <h2 class="text-lg font-bold mb-4"><%= gettext("Credentials & Research") %></h2>
                   
                   <div class="space-y-6">
                      <%= if @doctor.board_certifications != [] do %>
                        <div>
                          <h3 class="text-sm font-semibold text-base-content/70 mb-2"><%= gettext("Board Certifications") %></h3>
                          <ul class="space-y-1">
                             <%= for cert <- @doctor.board_certifications do %>
                                <li class="flex items-center gap-2 text-sm">
                                  <.icon name="hero-check-circle" class="w-4 h-4 text-success" /> <%= cert %>
                                </li>
                             <% end %>
                          </ul>
                        </div>
                      <% end %>
                      
                      <%= if @doctor.awards != [] do %>
                        <div>
                          <h3 class="text-sm font-semibold text-base-content/70 mb-2"><%= gettext("Awards & Recognition") %></h3>
                           <ul class="space-y-1">
                             <%= for award <- @doctor.awards do %>
                                <li class="flex items-start gap-2 text-sm">
                                  <.icon name="hero-trophy" class="w-4 h-4 text-warning shrink-0 mt-0.5" /> <%= award %>
                                </li>
                             <% end %>
                          </ul>
                        </div>
                      <% end %>

                      <%= if @doctor.publications != [] do %>
                        <div>
                           <h3 class="text-sm font-semibold text-base-content/70 mb-2"><%= gettext("Selected Publications") %></h3>
                           <ul class="space-y-2">
                             <%= for pub <- @doctor.publications do %>
                                <li class="text-sm text-base-content/80 italic border-l-2 border-base-300 pl-3">
                                  "<%= pub %>"
                                </li>
                             <% end %>
                           </ul>
                        </div>
                      <% end %>
                   </div>
                </div>
              </section>
            <% end %>
          </div>

          <%!-- Right Column: Logistics (1/3) --%>
          <div class="lg:col-span-1 space-y-6">
             
             <%!-- Location Card --%>
             <div class="card bg-base-100 shadow-md border border-base-200">
                <div class="card-body p-5">
                   <h3 class="font-bold flex items-center gap-2 mb-3">
                      <.icon name="hero-map-pin" class="w-5 h-5 text-accent" />
                      <%= gettext("Location") %>
                   </h3>
                   <div class="text-sm space-y-1">
                      <p class="font-medium"><%= @doctor.address %></p>
                      <p class="text-base-content/70"><%= @doctor.city %>, Greece</p>
                   </div>
                   
                   <div class="h-32 bg-base-200 rounded-lg mt-4 flex items-center justify-center text-base-content/30 border border-base-300 inset-shadow-sm">
                      <span class="text-xs">Map Placeholder</span>
                   </div>
                   
                   <%!-- Accessibility --%>
                    <%= if @doctor.accessibility_items != [] do %>
                      <div class="mt-4 flex flex-wrap gap-2">
                        <%= for item <- @doctor.accessibility_items do %>
                          <div class="badge badge-xs badge-ghost gap-1 py-2 px-2">
                            <.icon name="hero-check" class="w-3 h-3 text-success" /> <%= item %>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                </div>
             </div>

             <%!-- Insurance --%>
             <%= if @doctor.insurance_networks != [] do %>
                <div class="card bg-base-100 shadow-md border border-base-200">
                   <div class="card-body p-5">
                      <h3 class="font-bold flex items-center gap-2 mb-3">
                         <.icon name="hero-credit-card" class="w-5 h-5 text-secondary" />
                         <%= gettext("Insurance") %>
                      </h3>
                      <div class="flex flex-wrap gap-2">
                       <%= for insurance <- @doctor.insurance_networks do %>
                         <div class="badge badge-outline"><%= insurance %></div>
                       <% end %>
                     </div>
                  </div>
                </div>
             <% end %>
          </div>

        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    doctor = Doctors.get_doctor_with_details!(id)

    {:ok,
     assign(socket,
       page_title: "Dr. #{doctor.first_name} #{doctor.last_name}",
       doctor: doctor
     )}
  end
end
