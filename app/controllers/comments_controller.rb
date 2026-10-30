class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: %i[ show update destroy ]

  # GET /posts/1/comments
  def index
    render json: @post.comments
  end

  # GET /posts/1/comments/1
  def show
    render json: @comment
  end

  # POST /posts/1/comments
  def create
    @comment = @post.comments.new(comment_params)

    if @comment.save
      render json: @comment, status: :created
    else
      render json: @comment.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /posts/1/comments/1
  def update
    if @comment.update(comment_params)
      render json: @comment
    else
      render json: @comment.errors, status: :unprocessable_content
    end
  end

  # DELETE /posts/1/comments/1
  def destroy
    @comment.destroy!
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end

    def set_comment
      @comment = @post.comments.find(params.expect(:id))
    end

    def comment_params
      params.expect(comment: [ :comment ])
    end
end
