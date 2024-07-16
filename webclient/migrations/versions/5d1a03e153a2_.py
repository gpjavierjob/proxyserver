"""empty message

Revision ID: 5d1a03e153a2
Revises: 9af4dd601ade
Create Date: 2024-04-12 16:39:11.692190

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '5d1a03e153a2'
down_revision = '9af4dd601ade'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('servers',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('created_on', sa.DateTime(timezone=True), nullable=True),
    sa.Column('updated_on', sa.DateTime(timezone=True), nullable=True),
    sa.Column('name', sa.String(), nullable=False),
    sa.Column('hostname', sa.String(), nullable=False),
    sa.Column('namespace', sa.String(), nullable=False),
    sa.Column('port', sa.SmallInteger(), nullable=False),
    sa.Column('protocol', sa.String(), nullable=False),
    sa.Column('appversion', sa.String(), nullable=False),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('name')
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('servers')
    # ### end Alembic commands ###