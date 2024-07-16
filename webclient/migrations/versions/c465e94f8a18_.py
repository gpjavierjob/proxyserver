"""empty message

Revision ID: c465e94f8a18
Revises: c425979bc5de
Create Date: 2024-05-31 17:12:50.435895

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'c465e94f8a18'
down_revision = 'c425979bc5de'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('audit',
    sa.Column('created_on', sa.DateTime(timezone=True), nullable=True),
    sa.Column('created_by', sa.String(), nullable=True),
    sa.Column('updated_on', sa.DateTime(timezone=True), nullable=True),
    sa.Column('updated_by', sa.String(), nullable=True),
    sa.Column('id', sa.Integer(), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('auto',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    op.drop_table('auto_increment_model')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('auto_increment_model',
    sa.Column('id', sa.INTEGER(), nullable=False),
    sa.Column('created_on', sa.DATETIME(), nullable=True),
    sa.Column('created_by', sa.VARCHAR(), nullable=True),
    sa.Column('updated_on', sa.DATETIME(), nullable=True),
    sa.Column('updated_by', sa.VARCHAR(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    op.drop_table('auto')
    op.drop_table('audit')
    # ### end Alembic commands ###