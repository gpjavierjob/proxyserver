"""empty message

Revision ID: 2e2dbf1752b3
Revises: 4c6db090cc4e
Create Date: 2024-05-29 16:19:44.920463

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '2e2dbf1752b3'
down_revision = '4c6db090cc4e'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('clients', schema=None) as batch_op:
        batch_op.add_column(sa.Column('email', sa.String(), nullable=True))

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('clients', schema=None) as batch_op:
        batch_op.drop_column('email')

    # ### end Alembic commands ###
