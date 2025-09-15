require 'rails_helper'

RSpec.describe PackingListsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:other_road_trip) { create(:road_trip, user: other_user) }

  # Helper to sign in user
  def sign_in_user(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  before do
    sign_in_user(user)
  end

  describe 'GET #index' do
    let!(:private_list_by_user) { create(:packing_list, :private_list, road_trip: road_trip, user: user) }
    let!(:public_list_by_user) { create(:packing_list, :public_list, road_trip: road_trip, user: user) }
    let!(:private_list_by_other) { create(:packing_list, :private_list, road_trip: road_trip, user: other_user) }
    let!(:public_list_by_other) { create(:packing_list, :public_list, road_trip: road_trip, user: other_user) }

    before do
      # Add other_user as participant to the road trip
      road_trip.add_participant(other_user)
    end

    it 'shows only visible packing lists to the current user' do
      get road_trip_packing_lists_path(road_trip)

      expect(response).to have_http_status(:ok)
      # Check response contains the expected lists by checking the response body
      expect(response.body).to include(private_list_by_user.name)
      expect(response.body).to include(public_list_by_user.name)
      expect(response.body).to include(public_list_by_other.name)
    end

    it 'does not show private lists owned by other users' do
      get road_trip_packing_lists_path(road_trip)

      # Check that private list by other user is not in the response
      expect(response.body).not_to include(private_list_by_other.name)
    end

    context 'when user is not authorized for the road trip' do
      it 'redirects with error' do
        get road_trip_packing_lists_path(other_road_trip)

        expect(response).to redirect_to(road_trips_path)
        expect(flash[:alert]).to eq("You don't have access to this road trip.")
      end
    end
  end

  describe 'GET #show' do
    let(:packing_list) { create(:packing_list, road_trip: road_trip, user: user) }
    let(:private_list_by_other) { create(:packing_list, :private_list, road_trip: road_trip, user: other_user) }
    let(:public_list_by_other) { create(:packing_list, :public_list, road_trip: road_trip, user: other_user) }

    before do
      road_trip.add_participant(other_user)
    end

    it 'shows own packing list' do
      get road_trip_packing_list_path(road_trip, packing_list)

      expect(response).to have_http_status(:ok)
      expect(assigns(:packing_list)).to eq(packing_list)
    end

    it 'shows public lists by other users' do
      get road_trip_packing_list_path(road_trip, public_list_by_other)

      expect(response).to have_http_status(:ok)
      expect(assigns(:packing_list)).to eq(public_list_by_other)
    end

    it 'does not show private lists by other users' do
      get road_trip_packing_list_path(road_trip, private_list_by_other)

      expect(response).to redirect_to(road_trip_packing_lists_path(road_trip))
      expect(flash[:alert]).to eq("Packing list not found.")
    end
  end

  describe 'GET #new' do
    it 'renders the new packing list form' do
      get new_road_trip_packing_list_path(road_trip)

      expect(response).to have_http_status(:ok)
      expect(assigns(:packing_list)).to be_a_new(PackingList)
      expect(assigns(:packing_list).road_trip).to eq(road_trip)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        packing_list: {
          name: 'Test Packing List',
          visibility: 'private'
        }
      }
    end

    it 'creates a new packing list with current user as owner' do
      expect do
        post road_trip_packing_lists_path(road_trip), params: valid_params
      end.to change(PackingList, :count).by(1)

      packing_list = PackingList.last
      expect(packing_list.user).to eq(user)
      expect(packing_list.road_trip).to eq(road_trip)
      expect(packing_list.name).to eq('Test Packing List')
      expect(packing_list.visibility).to eq('private')
    end

    it 'creates a public packing list when specified' do
      valid_params[:packing_list][:visibility] = 'public'

      post road_trip_packing_lists_path(road_trip), params: valid_params

      packing_list = PackingList.last
      expect(packing_list.visibility).to eq('public')
    end

    it 'redirects to the created packing list' do
      post road_trip_packing_lists_path(road_trip), params: valid_params

      packing_list = PackingList.last
      expect(response).to redirect_to(road_trip_packing_list_path(road_trip, packing_list))
      expect(flash[:notice]).to eq('Packing list was successfully created.')
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          packing_list: {
            name: '',
            visibility: 'invalid'
          }
        }
      end

      it 'does not create a packing list' do
        expect do
          post road_trip_packing_lists_path(road_trip), params: invalid_params
        end.not_to change(PackingList, :count)
      end

      it 'renders the new form with errors' do
        post road_trip_packing_lists_path(road_trip), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:packing_list).errors).not_to be_empty
      end
    end
  end

  describe 'GET #edit' do
    let(:packing_list) { create(:packing_list, road_trip: road_trip, user: user) }
    let(:other_users_list) { create(:packing_list, road_trip: road_trip, user: other_user) }

    before do
      road_trip.add_participant(other_user)
    end

    it 'allows editing own packing list' do
      get edit_road_trip_packing_list_path(road_trip, packing_list)

      expect(response).to have_http_status(:ok)
      expect(assigns(:packing_list)).to eq(packing_list)
    end

    it 'prevents editing other users packing lists' do
      get edit_road_trip_packing_list_path(road_trip, other_users_list)

      expect(response).to redirect_to(road_trip_packing_lists_path(road_trip))
      expect(flash[:alert]).to eq("You can only edit your own packing lists.")
    end
  end

  describe 'PATCH #update' do
    let(:packing_list) { create(:packing_list, road_trip: road_trip, user: user) }
    let(:other_users_list) { create(:packing_list, road_trip: road_trip, user: other_user) }

    before do
      road_trip.add_participant(other_user)
    end

    let(:update_params) do
      {
        packing_list: {
          name: 'Updated Packing List',
          visibility: 'public'
        }
      }
    end

    it 'allows updating own packing list' do
      patch road_trip_packing_list_path(road_trip, packing_list), params: update_params

      packing_list.reload
      expect(packing_list.name).to eq('Updated Packing List')
      expect(packing_list.visibility).to eq('public')
      expect(response).to redirect_to(road_trip_packing_list_path(road_trip, packing_list))
      expect(flash[:notice]).to eq('Packing list was successfully updated.')
    end

    it 'prevents updating other users packing lists' do
      patch road_trip_packing_list_path(road_trip, other_users_list), params: update_params

      expect(response).to redirect_to(road_trip_packing_lists_path(road_trip))
      expect(flash[:alert]).to eq("You can only edit your own packing lists.")
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          packing_list: {
            name: '',
            visibility: 'invalid'
          }
        }
      end

      it 'does not update the packing list' do
        original_name = packing_list.name
        patch road_trip_packing_list_path(road_trip, packing_list), params: invalid_params

        packing_list.reload
        expect(packing_list.name).to eq(original_name)
      end

      it 'renders the edit form with errors' do
        patch road_trip_packing_list_path(road_trip, packing_list), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:packing_list).errors).not_to be_empty
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:packing_list) { create(:packing_list, road_trip: road_trip, user: user) }
    let!(:other_users_list) { create(:packing_list, road_trip: road_trip, user: other_user) }

    before do
      road_trip.add_participant(other_user)
    end

    it 'allows deleting own packing list' do
      expect do
        delete road_trip_packing_list_path(road_trip, packing_list)
      end.to change(PackingList, :count).by(-1)

      expect(response).to redirect_to(road_trip_packing_lists_path(road_trip))
      expect(flash[:notice]).to eq('Packing list was successfully deleted.')
    end

    it 'prevents deleting other users packing lists' do
      expect do
        delete road_trip_packing_list_path(road_trip, other_users_list)
      end.not_to change(PackingList, :count)

      expect(response).to redirect_to(road_trip_packing_lists_path(road_trip))
      expect(flash[:alert]).to eq("You can only edit your own packing lists.")
    end
  end

  describe 'authorization' do
    context 'when user is not logged in' do
      before do
        delete logout_path
      end

      it 'redirects to login page' do
        get road_trip_packing_lists_path(road_trip)

        expect(response).to redirect_to(login_path)
      end
    end
  end
end
