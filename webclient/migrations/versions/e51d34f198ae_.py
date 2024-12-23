"""empty message

Revision ID: e51d34f198ae
Revises: 886630ee0b79
Create Date: 2024-04-24 16:48:37.601846

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'e51d34f198ae'
down_revision = '886630ee0b79'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('servers', schema=None) as batch_op:
        batch_op.add_column(sa.Column('state', sa.String(), nullable=True))
        batch_op.add_column(sa.Column('errmsg', sa.String(), nullable=True))

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('servers', schema=None) as batch_op:
        batch_op.drop_column('errmsg')
        batch_op.drop_column('state')

    # ### end Alembic commands ###
