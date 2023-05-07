class CoursesController < ApplicationController
  skip_before_action :authenticate_user!, :only => [:show]
  before_action :set_course, only: [:show, :edit, :update, :destroy, :approve, :unapprove, :analytics]

  def index
    #if current_user.has_role?(:admin)
    #  @ransack_courses = Course.ransack(params[:courses_search], search_key: :courses_search)
    #  @courses = @ransack_courses.result.includes(:user)
    #else
    #  redirect_to root_path, alert: 'You do not have access'
    #end
    # @courses = @ransack_courses.result.includes(:user)
    @ransack_path = courses_path
    @ransack_courses = Course.published.approved.ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result)
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
  end

  def learning
    @ransack_path = learning_courses_path
    @ransack_courses = Course.joins(:enrollments).where(enrollments: {user: current_user}).ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result)
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
    render 'index'
  end

  def pending_review
    @ransack_path = pending_review_courses_path
    @ransack_courses = Course.joins(:enrollments).merge(Enrollment.pending_review.where(user: current_user)).ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result)
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
    render 'index'
  end

  def teaching
    @ransack_path = teaching_courses_path
    @ransack_courses = Course.where(user: current_user).ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result)
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
    render 'index'
  end

  def unapproved
    @ransack_path = unapproved_courses_path
    @ransack_courses = Course.unapproved.ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result)
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
    render 'index'
  end

  def approve
    authorize @course, :approve?
    @course.update_attribute(:approved, true)
    redirect_to @course, notice: "Course approved and visible!"
  end

  def unapprove
    authorize @course, :approve?
    @course.update_attribute(:approved, false)
    redirect_to @course, notice: "Course upapproved and hidden!"
  end

  def analytics
    authorize @course, :owner?
  end

  def show
    authorize @course
    @lessons = @course.lessons.rank(:row_order)
    @enrollments_with_review = @course.enrollments.reviewed
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "#{@course.title}, #{current_user.email}",
        page_size: 'A4',
        template: "courses/show.pdf.haml",
        layout: "pdf.html.haml",
        orientation: "Portrait",
        lowquality: true,
        zoom: 1,
        dpi: 75
      end
    end
  end

  def new
    @course = Course.new
    authorize @course
    @tags = Tag.all
  end

  def edit
    authorize @course
    @tags = Tag.all
  end

  def create
    @course = Course.new(course_params)
    authorize @course
    @course.user = current_user

    respond_to do |format|
      if @course.save
        format.html { redirect_to @course, notice: 'Course was successfully created.' }
        format.json { render :show, status: :created, location: @course }
      else
        @tags = Tag.all
        format.html { render :new }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @course
    respond_to do |format|
      if @course.update(course_params)
        format.html { redirect_to @course, notice: 'Course was successfully updated.' }
        format.json { render :show, status: :ok, location: @course }
      else
        @tags = Tag.all
        format.html { render :edit }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @course
    if @course.destroy
      respond_to do |format|
        format.html { redirect_to teaching_courses_path, notice: 'Course was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      redirect_to @course, alert: 'Course has enrollments. Can not be destroyed.'
    end
  end

  private
    def set_course
      @course = Course.friendly.find(params[:id])
    end

    def course_params
      params.require(:course).permit(:title, :description, :short_description, :price,
        :published, :language, :level, :avatar, tag_ids: [])
    end
end