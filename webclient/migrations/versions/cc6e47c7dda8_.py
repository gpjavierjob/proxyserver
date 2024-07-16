"""empty message

Revision ID: cc6e47c7dda8
Revises: c465e94f8a18
Create Date: 2024-06-03 14:42:35.953551

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'cc6e47c7dda8'
down_revision = 'c465e94f8a18'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('auto', schema=None) as batch_op:
        batch_op.add_column(sa.Column('archived', sa.Boolean(), nullable=True))
        batch_op.add_column(sa.Column('created_on', sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column('created_by', sa.String(), nullable=True))
        batch_op.add_column(sa.Column('updated_on', sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column('updated_by', sa.String(), nullable=True))

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('auto', schema=None) as batch_op:
        batch_op.drop_column('updated_by')
        batch_op.drop_column('updated_on')
        batch_op.drop_column('created_by')
        batch_op.drop_column('created_on')
        batch_op.drop_column('archived')

    # ### end Alembic commands ###
